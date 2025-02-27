WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        1 AS level
    FROM 
        cast_info ca
    WHERE 
        ca.role_id = (SELECT id FROM role_type WHERE role = 'Lead')  
  
    UNION ALL
  
    SELECT 
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM 
        cast_info ca
    JOIN 
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.role_id <> (SELECT id FROM role_type WHERE role = 'Lead')  
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    MAX(m.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE NULL END) AS avg_production_year,
    CASE 
        WHEN COUNT(DISTINCT m.id) = 0 THEN 'No films'
        WHEN COUNT(DISTINCT m.id) BETWEEN 1 AND 5 THEN 'Few films'
        ELSE 'Many films'
    END AS film_experience
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    title m ON m.id = ci.movie_id  
LEFT JOIN 
    ActorHierarchy ah ON ci.person_id = ah.person_id
WHERE 
    a.name IS NOT NULL
AND 
    (mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') 
    OR 
    mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%'))
GROUP BY 
    a.name
ORDER BY 
    movie_count DESC;