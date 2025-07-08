
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        m.kind_id, 
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title, 
        m.production_year, 
        m.kind_id, 
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    AVG(t.production_year) AS average_year,
    LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS titles,
    MAX(t.production_year) AS recent_movie_year
FROM 
    aka_name AS a
LEFT JOIN 
    cast_info AS c ON a.person_id = c.person_id
LEFT JOIN 
    movie_info AS mi ON c.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
LEFT JOIN 
    title AS t ON c.movie_id = t.id
LEFT JOIN 
    movie_hierarchy AS mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL 
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    recent_movie_year DESC
LIMIT 10;
