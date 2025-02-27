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
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.production_year) AS avg_production_year,
    string_agg(DISTINCT mt.title, ', ') AS titles,
    MAX(CASE WHEN ci.role_id IS NULL THEN 'Unknown' ELSE rt.role END) AS main_role
FROM 
    aka_name a
INNER JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movie_count DESC;
