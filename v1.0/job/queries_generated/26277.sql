WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id AS actor_id,
        a.name AS actor_name,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE title LIKE '%Matrix%')
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name,
        ah.depth + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.actor_id)
    WHERE 
        ah.depth < 3
)
SELECT 
    ah.actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    ARRAY_AGG(DISTINCT t.title) AS movies_co_starred,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    ActorHierarchy ah
JOIN 
    cast_info c ON ah.actor_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
GROUP BY 
    ah.actor_name
ORDER BY 
    movie_count DESC
LIMIT 10;

