WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        ah.actor_id,
        ah.actor_name,
        m.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ah.actor_id ORDER BY t.production_year DESC) AS rn
    FROM 
        ActorHierarchy ah
    JOIN 
        movie_companies m ON ah.movie_id = m.movie_id
    JOIN 
        aka_title t ON m.movie_id = t.movie_id
    WHERE 
        t.production_year > 2000
)

SELECT 
    ah.actor_id,
    ah.actor_name,
    COUNT(DISTINCT ah.movie_id) AS total_movies,
    STRING_AGG(DISTINCT ah.movie_title || ' (' || ah.production_year || ')', '; ') AS movies,
    MAX(ah.production_year) AS latest_movie_year
FROM 
    ActorHierarchy ah
WHERE 
    ah.rn <= 3  -- Limit to the latest 3 movies
GROUP BY 
    ah.actor_id, ah.actor_name
ORDER BY 
    total_movies DESC
LIMIT 10;

-- Benchmarking performance: compare this result with other similar queries and observe execution time.
