WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        linked.title,
        linked.production_year,
        mh.depth + 1,
        mh.path || linked.title
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title linked ON ml.linked_movie_id = linked.id
    WHERE 
        mh.depth < 5 -- Limit depth to prevent excessive recursion
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT kc.keyword) AS keywords,
    SUM(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    MAX(mh.depth) AS max_link_depth,
    MAX(mh.path) AS full_path
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = at.id
WHERE
    at.production_year BETWEEN 2000 AND 2020
    AND ak.name IS NOT NULL
    AND ak.surname_pcode IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year
ORDER BY 
    MAX(mh.depth) DESC, ak.name ASC
LIMIT 100
OFFSET 0;
