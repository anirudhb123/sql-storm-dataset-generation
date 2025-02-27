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
        c.movie_id = (SELECT id FROM aka_title WHERE title = 'Inception' LIMIT 1)
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name,
        h.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy h ON c.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = h.person_id)
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS total_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    COALESCE(SUM(m.produced_year), 0) AS total_produced_year,
    AVG(COALESCE(m.production_year, 0)) AS avg_production_year,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT m.id) DESC) AS rank
FROM 
    ActorHierarchy a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT m.id) > 1
ORDER BY 
    rank
WITHIN GROUP (ORDER BY a.actor_name)
LIMIT 10;
