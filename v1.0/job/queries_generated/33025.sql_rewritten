WITH RECURSIVE ActorHierarchy AS (
    
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    
    UNION ALL
    
    
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ah.level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        movie_link ml ON ah.movie_title = (SELECT title FROM aka_title WHERE id = ml.linked_movie_id LIMIT 1)
    JOIN 
        cast_info ci ON ml.linked_movie_id = ci.movie_id 
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
)
SELECT 
    ah.actor_name,
    COUNT(DISTINCT ah.movie_title) AS movies_count,
    MAX(ah.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT t.title || ' (' || t.production_year || ')', ', ') AS movie_list
FROM 
    ActorHierarchy ah
JOIN 
    aka_title t ON ah.movie_title = t.title
WHERE 
    ah.production_year > 2000
GROUP BY 
    ah.actor_name
HAVING 
    COUNT(DISTINCT ah.movie_title) > 3
ORDER BY 
    movies_count DESC;