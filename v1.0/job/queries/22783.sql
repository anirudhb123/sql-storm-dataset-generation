WITH RecursiveActorFilmography AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY at.production_year DESC) AS film_rank
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title at ON ci.movie_id = at.id
    JOIN name a ON ak.person_id = a.imdb_id
    WHERE a.gender = 'M' 
      AND at.production_year IS NOT NULL
),
PopularMovies AS (
    SELECT 
        at.id AS movie_id, 
        at.title AS movie_title,
        COUNT(ci.person_id) AS total_cast,
        MAX(at.production_year) AS latest_year
    FROM aka_title at
    JOIN cast_info ci ON at.id = ci.movie_id
    GROUP BY at.id, at.title
    HAVING COUNT(ci.person_id) > 5
),
HighRankedActors AS (
    SELECT 
        actor_id, 
        actor_name, 
        movie_title, 
        production_year
    FROM RecursiveActorFilmography
    WHERE film_rank <= 3
)
SELECT 
    h.actor_name,
    h.movie_title,
    h.production_year,
    COALESCE(p.total_cast, 0) AS total_cast_in_popular_movies,
    CASE 
        WHEN COALESCE(p.total_cast, 0) > 10 
        THEN 'Superstar'
        WHEN COALESCE(p.total_cast, 0) BETWEEN 6 AND 10 
        THEN 'Known'
        ELSE 'Unknown'
    END AS actor_popularity
FROM HighRankedActors h
LEFT JOIN PopularMovies p ON h.movie_title = p.movie_title AND h.production_year = p.latest_year
WHERE h.production_year BETWEEN 2000 AND 2023
ORDER BY h.actor_name, h.production_year DESC
LIMIT 50
OFFSET 0;
