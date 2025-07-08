
WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mc.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_chain mc ON ml.movie_id = mc.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id 
    WHERE 
        mc.level < 5  
)

SELECT 
    t.title AS original_movie,
    LISTAGG(DISTINCT mc.title, ', ') WITHIN GROUP (ORDER BY mc.title) AS linked_movies,
    COUNT(DISTINCT CASE WHEN c.role_id IS NOT NULL THEN c.person_id END) AS total_actors,
    MIN(t.production_year) AS earliest_production_year
FROM 
    movie_chain mc
LEFT JOIN 
    complete_cast cc ON mc.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_title t ON mc.movie_id = t.id
GROUP BY 
    mc.movie_id, t.title
HAVING 
    COUNT(DISTINCT c.role_id) > 0  
ORDER BY 
    earliest_production_year DESC
LIMIT 10;
