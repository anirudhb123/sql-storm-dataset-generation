WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.id AS cast_id,
        p.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        CAST(1 AS INTEGER) AS level
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id 
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        CONCAT(c.id, '_R') AS cast_id,
        p.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info c ON ah.cast_id = c.id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id 
    WHERE 
        t.production_year < ah.production_year
)
SELECT 
    ah.actor_name,
    ah.movie_title,
    ah.production_year,
    COUNT(*) OVER (PARTITION BY ah.actor_name) AS movie_count,
    MAX(ah.level) OVER (PARTITION BY ah.actor_name) AS max_level
FROM 
    ActorHierarchy ah
WHERE 
    ah.production_year = (SELECT MAX(production_year) FROM aka_title)
    OR ah.actor_name IS NOT NULL
ORDER BY 
    ah.actor_name, ah.production_year DESC
LIMIT 10;

-- Performance benchmarking based on the following:
-- 1. Recursive CTE to create a hierarchy of actors and the movies they have been part of.
-- 2. Window functions to count movies per actor and determine the maximum level in the hierarchy.
-- 3. Filters based on production year to limit the dataset.
-- 4. Ordering and limiting results for better performance analysis.
