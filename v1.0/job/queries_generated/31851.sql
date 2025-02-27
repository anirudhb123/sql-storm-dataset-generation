WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    c.role_id,
    COUNT(DISTINCT c.id) AS total_cast_members,
    SUM(CASE WHEN p.info_type_id = (SELECT id FROM info_type WHERE info = 'Height') 
             THEN CAST(p.info AS DECIMAL) ELSE NULL END) AS total_height,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COUNT(DISTINCT c.id) DESC) AS role_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id AND p.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Height', 'Weight'))
JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
GROUP BY 
    a.name, mt.title, mt.production_year, c.role_id
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    mt.production_year DESC, total_cast_members DESC, actor_name;
