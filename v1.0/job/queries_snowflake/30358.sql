
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        1 AS level
    FROM 
        cast_info ci
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Lead Actor')
    
    UNION ALL
    
    SELECT 
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ci.role_id != (SELECT id FROM role_type WHERE role = 'Lead Actor')
)
SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT ah.person_id) AS total_cast,
    AVG(ah.level) AS average_cast_level,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    ActorHierarchy ah
JOIN 
    aka_name ak ON ak.person_id = ah.person_id
JOIN 
    aka_title at ON at.id = ah.movie_id
JOIN 
    title t ON t.id = at.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ah.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    t.production_year IS NOT NULL AND t.production_year > 2000
GROUP BY 
    ak.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ah.person_id) > 2
ORDER BY 
    t.production_year DESC, total_cast DESC;
