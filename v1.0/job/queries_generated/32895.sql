WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id IN (
            SELECT movie_id FROM cast_info WHERE person_id = ah.person_id
        )
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    h.actor_name,
    t.title,
    t.production_year,
    COUNT(DISTINCT c2.person_id) AS co_actors,
    SUM(CASE WHEN m.info IS NULL THEN 0 ELSE 1 END) AS has_movie_info
FROM 
    ActorHierarchy h
JOIN 
    cast_info c ON h.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    cast_info c2 ON t.id = c2.movie_id AND c2.person_id <> h.person_id
GROUP BY 
    h.actor_name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT c2.person_id) > 5
ORDER BY 
    t.production_year DESC,
    co_actors DESC
LIMIT 10;

