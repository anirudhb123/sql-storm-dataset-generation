WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m 
    WHERE 
        m.production_year >= 2000 
    
    UNION ALL 
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS acting_roles,
    MAX(COALESCE(p.info, 'No Info')) AS personal_info
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_info p ON mh.movie_id = p.movie_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio')
LEFT JOIN 
    aka_title mt ON c.movie_id = mt.id
WHERE 
    c.nr_order IS NOT NULL
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC, avg_production_year DESC;
