WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.depth < 3  -- Limit the depth to avoid infinite recursion
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(CASE 
            WHEN pi.info IS NULL THEN 0
            ELSE LENGTH(pi.info) 
        END) AS avg_info_length,
    ROW_NUMBER() OVER(PARTITION BY ak.id ORDER BY mt.production_year DESC) AS rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%biography%')
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.linked_movie_id
WHERE 
    ak.name IS NOT NULL 
AND 
    mt.production_year IS NOT NULL
GROUP BY 
    ak.id, mt.id
HAVING 
    COUNT(DISTINCT kc.keyword) > 5
ORDER BY 
    rank, ak.name;
