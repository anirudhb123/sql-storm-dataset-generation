WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

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
    at.title AS movie_title,
    at.production_year,
    COALESCE(cc.kind, 'Unknown') AS company_type,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(person_info_count) AS average_info_count,
    MAX(mh.level) AS max_hierarchy_level
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_type cc ON mc.company_type_id = cc.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    (SELECT 
         person_id, 
         COUNT(*) AS person_info_count 
     FROM 
         person_info 
     GROUP BY 
         person_id) pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND at.production_year BETWEEN 2000 AND 2023 
GROUP BY 
    ak.name, at.title, at.production_year, cc.kind
HAVING 
    COUNT(DISTINCT kc.keyword) > 1
ORDER BY 
    average_info_count DESC, 
    ak.name;
