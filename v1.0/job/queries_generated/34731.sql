WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    ARRAY_AGG(DISTINCT mt.title) AS movie_titles,
    AVG(mh.production_year) AS avg_production_year,
    SUM(CASE WHEN ak.surname_pcode IS NOT NULL THEN 1 ELSE 0 END) AS valid_surnames,
    SUM(CASE WHEN mt.kind_id IS NOT NULL THEN 1 ELSE 0 END) AS valid_kinds,
    STRING_AGG(DISTINCT co.name, ', ' ORDER BY co.name) AS company_names
FROM 
    cast_info ci
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movie_count DESC, actor_name;
