
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        p.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Lead Actor')

    UNION ALL

    SELECT 
        ci.person_id,
        CONCAT(p.name, ' (Supporting)') AS actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id LIMIT 1)
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        ci.role_id != (SELECT id FROM role_type WHERE role = 'Lead Actor')
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    MAX(m.production_year) AS last_movie_year
FROM 
    ActorHierarchy a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.actor_name
ORDER BY 
    movie_count DESC, last_movie_year DESC
LIMIT 10;
