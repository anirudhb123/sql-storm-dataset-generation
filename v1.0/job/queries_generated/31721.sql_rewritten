WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id AS actor_id,
        ct.kind AS role,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM movie_info WHERE info LIKE '%blockbuster%')  

    UNION ALL

    SELECT 
        c.person_id,
        ct.kind,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id IN (SELECT linked_movie_id FROM movie_link WHERE movie_id = ah.actor_id)
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    WHERE 
        ah.level < 3  
)

SELECT 
    a.actor_id,
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    MAX(CASE WHEN t.production_year IS NULL THEN 'Unknown' ELSE CAST(t.production_year AS TEXT) END) AS last_known_year,
    ROW_NUMBER() OVER (PARTITION BY a.actor_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
FROM 
    ActorHierarchy a
JOIN 
    aka_name ak ON a.actor_id = ak.person_id
JOIN 
    cast_info c ON a.actor_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
GROUP BY 
    a.actor_id, ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) >= 3  
ORDER BY 
    rank
LIMIT 10;