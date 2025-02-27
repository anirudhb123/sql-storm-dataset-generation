WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title AS movie_title,
        mh.depth + 1 AS depth
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title a ON ml.linked_movie_id = a.id
)
SELECT 
    ak.person_id,
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(tc.production_year) AS average_production_year,
    STRING_AGG(DISTINCT akname.name, ', ') AS all_names,
    MAX(tc.production_year) AS last_production_year,
    MIN(tc.production_year) AS first_production_year
FROM aka_name ak
LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN aka_title tc ON mh.movie_id = tc.id
LEFT JOIN char_name akname ON ak.id = akname.id
WHERE ak.name IS NOT NULL 
GROUP BY ak.person_id, ak.name
HAVING COUNT(DISTINCT mh.movie_id) > 2 
   OR (MAX(tc.production_year) < 2020 AND MIN(tc.production_year) > 2010)
ORDER BY movie_count DESC, actor_name;
