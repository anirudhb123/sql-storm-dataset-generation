WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT mt.id, mt.title, mt.production_year, mh.level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(pi.info::int) AS avg_personal_info
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title mt ON ci.movie_id = mt.id
LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN person_info pi ON ak.person_id = pi.person_id
LEFT JOIN MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year > 2000
GROUP BY ak.name, mt.title, mh.production_year
HAVING COUNT(DISTINCT mk.keyword) > 0
ORDER BY avg_personal_info DESC, ak.name
LIMIT 50;

This query systematically retrieves actor names along with the titles and production years of movies they appeared in, while also calculating the number of unique keywords associated with each movie and the average personal information score of each actor. It employs CTEs for hierarchical movie linking, left joins to include potentially missing links, and various aggregate functions to summarize the results. The use of HAVING and filtering predicates helps to ensure the output is both concise and relevant.
