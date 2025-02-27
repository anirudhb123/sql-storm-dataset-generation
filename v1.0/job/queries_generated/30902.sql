WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    AVG(COALESCE(CAST(mi.info AS INTEGER), 0)) AS average_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    at.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, at.title, at.production_year, mh.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 AND AVG(COALESCE(CAST(mi.info AS INTEGER), 0)) > 1000000
ORDER BY 
    hierarchy_level DESC, a.name;
