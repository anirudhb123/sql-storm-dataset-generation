WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS hierarchy_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level,
        CAST(mh.hierarchy_path || ' > ' || at.title AS VARCHAR(255)) AS hierarchy_path
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    SUM(CASE 
        WHEN mi.info_type_id IS NOT NULL THEN 1 
        ELSE 0 END) AS info_count,
    MAX(CASE 
        WHEN mi.info_type_id = 1 THEN mi.info 
        ELSE NULL END) AS summary_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
WHERE 
    a.name IS NOT NULL
AND 
    at.production_year >= 2000
GROUP BY 
    a.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    at.production_year DESC, num_companies DESC;
