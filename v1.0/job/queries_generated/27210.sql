WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.id AS actor_id,
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        1 AS level
    FROM 
        cast_info ca
    JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    JOIN 
        aka_title kt ON ca.movie_id = kt.movie_id
    WHERE 
        kt.production_year >= 2000  -- Filter for movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ca.id AS actor_id,
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        ah.level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ca ON ah.movie_id = ca.movie_id
    JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    JOIN 
        aka_title kt ON ca.movie_id = kt.movie_id
    WHERE 
        kt.production_year < 2000  -- Recur to find earlier movies that are related through the same actor
)

SELECT 
    a.actor_name,
    STRING_AGG(DISTINCT ah.movie_title, ', ') AS movies,
    MIN(ah.production_year) AS earliest_movie,
    MAX(ah.production_year) AS latest_movie,
    COUNT(DISTINCT ah.movie_title) AS total_movies
FROM 
    ActorHierarchy ah
JOIN 
    aka_name a ON ah.actor_id = a.id
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT ah.movie_title) > 5  -- Only include actors with more than 5 movies
ORDER BY 
    total_movies DESC
LIMIT 10;  -- Limit to top 10 actors with most movies
