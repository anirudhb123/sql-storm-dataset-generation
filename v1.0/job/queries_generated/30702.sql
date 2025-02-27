WITH RECURSIVE MovieActors AS (
    -- Base case: Get all movies with their actors
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
),
ActorMovieCount AS (
    -- CTE to get the count of movies for each actor
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM MovieActors
    GROUP BY actor_id, actor_name
),
TopActors AS (
    -- CTE to find the top actors based on the number of movies
    SELECT 
        actor_id,
        actor_name,
        movie_count,
        DENSE_RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM ActorMovieCount
    WHERE movie_count > 1
),
MoviesWithKeywords AS (
    -- CTE to get movies with their corresponding keywords
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
RelevantMovies AS (
    -- CTE to filter movies produced after 2000 with at least one keyword
    SELECT DISTINCT
        mwk.movie_id,
        mwk.title
    FROM MoviesWithKeywords mwk
    JOIN title t ON mwk.movie_id = t.id
    WHERE t.production_year > 2000 AND mwk.keyword IS NOT NULL
)
-- Final query: Join top actors with relevant movies and their associated keywords
SELECT 
    ta.actor_name,
    rm.title AS movie_title,
    rm.movie_id,
    CASE 
        WHEN mk.keyword IS NULL THEN 'No Keywords Available'
        ELSE mk.keyword
    END AS movie_keyword
FROM TopActors ta
JOIN RelevantMovies rm ON rm.movie_id IN (
    SELECT DISTINCT c.movie_id
    FROM cast_info c
    WHERE c.person_id IN (SELECT actor_id FROM TopActors)
)
LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
ORDER BY ta.rank, rm.title;
