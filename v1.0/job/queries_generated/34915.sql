WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id, 
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL
    
    SELECT 
        ci.person_id, 
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.person_id
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    AVG(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_presence,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(MAX(CASE WHEN c.note IS NOT NULL THEN c.note END), 'No notes') AS additional_notes
FROM 
    ActorHierarchy a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    movie_count DESC, actor_name ASC;
