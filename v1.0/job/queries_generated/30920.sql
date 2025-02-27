WITH RECURSIVE ActorHierarchy AS (
    SELECT ka.person_id, COUNT(ci.movie_id) AS movie_count, 
           ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY COUNT(ci.movie_id) DESC) AS rank
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    GROUP BY ka.person_id
),
PopularMovies AS (
    SELECT at.id AS movie_id, at.title, at.production_year, COUNT(DISTINCT ci.person_id) AS actor_count
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    GROUP BY at.id
    HAVING COUNT(DISTINCT ci.person_id) > 10
),
MovieDetails AS (
    SELECT at.title, at.production_year, kc.keyword AS movie_keyword,
           COALESCE(NULLIF(mii.info, ''), 'No Information') AS additional_info
    FROM aka_title at
    LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN movie_info mii ON at.id = mii.movie_id
    WHERE at.production_year >= 2000 AND at.kind_id = 1
),
FilteredActors AS (
    SELECT DISTINCT ka.id, ka.name,
           (SELECT COUNT(DISTINCT ci.movie_id) 
            FROM cast_info ci 
            WHERE ci.person_id = ka.person_id) AS movie_count
    FROM aka_name ka
    WHERE EXISTS (
        SELECT 1 FROM cast_info ci
        WHERE ci.person_id = ka.person_id AND ci.movie_id IN (
            SELECT movie_id FROM PopularMovies
        )
    )
)
SELECT A.name AS actor_name, 
       MD.title AS movie_title,
       MD.production_year AS release_year,
       MD.movie_keyword AS keyword,
       FA.movie_count AS total_movies,
       PM.actor_count AS participating_actors
FROM FilteredActors FA
JOIN MovieDetails MD ON FA.movie_count > 0
JOIN PopularMovies PM ON MD.title = PM.title
JOIN ActorHierarchy A ON FA.id = A.person_id
ORDER BY FA.movie_count DESC, A.rank ASC, MD.production_year DESC;

This SQL query establishes a recursive common table expression (CTE) hierarchy to analyze the count of movies associated with each actor and deliver pertinent data on movies that feature a large ensemble cast. It also filters and organizes valuable movie-related information, examining actors specifically involved in popular films released in the 21st century, while offering a comprehensive depiction of each actor's contributions to the film industry.
