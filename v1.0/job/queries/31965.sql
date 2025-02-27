
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id AS actor_id,
        t.title AS movie_title,
        t.production_year,
        NULL AS parent_actor,
        1 AS depth,
        t.id AS movie_id
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year = 2020

    UNION ALL

    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        ah.actor_id AS parent_actor,
        ah.depth + 1,
        t.id AS movie_id
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ci.movie_id = ah.movie_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    WHERE 
        cc.subject_id = ah.actor_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ah.movie_title) AS movie_count,
    SUM(CASE WHEN ah.depth = 1 THEN 1 ELSE 0 END) AS direct_movies,
    SUM(CASE WHEN ah.depth > 1 THEN 1 ELSE 0 END) AS indirectly_connected_movies,
    COALESCE(ROUND(AVG(COALESCE(ml.linked_movie_id, 0)), 2), 0) AS avg_linked_movies
FROM 
    actor_hierarchy ah
JOIN 
    aka_name ak ON ak.person_id = ah.actor_id
LEFT JOIN 
    movie_link ml ON ml.movie_id = ah.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT ah.movie_title) > 5
ORDER BY 
    movie_count DESC
LIMIT 10;
