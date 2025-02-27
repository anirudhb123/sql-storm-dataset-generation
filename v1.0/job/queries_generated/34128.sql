WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        ci.nr_order = 1

    UNION ALL

    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        ActorHierarchy ah ON ci.person_id = ah.person_id
    WHERE 
        ci.nr_order = ah.level + 1
),
AggregateTitles AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT title) AS movie_count,
        STRING_AGG(DISTINCT title, ', ') AS titles
    FROM 
        (SELECT 
            ci.person_id AS actor_id,
            t.title
        FROM 
            cast_info ci
        JOIN 
            aka_title t ON ci.movie_id = t.id
        WHERE 
            t.production_year >= 2000) AS subquery
    GROUP BY 
        actor_id
)
SELECT 
    ak.name AS actor_name,
    at.movie_count,
    at.titles
FROM 
    aka_name ak
LEFT JOIN 
    AggregateTitles at ON ak.person_id = at.actor_id
WHERE 
    ak.name IS NOT NULL
ORDER BY 
    movie_count DESC
LIMIT 10;


