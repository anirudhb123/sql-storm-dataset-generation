WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
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
    mh.depth AS hierarchy_depth,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(CASE WHEN mp.country_code IS NULL THEN 0 ELSE 1 END) AS has_company_info,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    (SELECT 
        id, CONCAT(name, ' (', country_code, ')') AS company_info 
     FROM 
        company_name
     WHERE 
        country_code IS NOT NULL) mp ON mc.company_id = mp.id
JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    at.production_year >= 2000 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, mh.depth
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    hierarchy_depth DESC, ak.name;
