WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title AS movie_title, 
           mt.production_year AS movie_year,
           1 AS hierarchy_level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT mt.id AS movie_id, 
           mt.title AS movie_title, 
           mt.production_year AS movie_year,
           mh.hierarchy_level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(ci.person_id) AS cast_count,
    SUM(CASE WHEN mk.id IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    AVG(mh.hierarchy_level) AS avg_hierarchy_level
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title at ON ci.movie_id = at.id
LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN movie_info mi ON at.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
LEFT JOIN movie_hierarchy mh ON at.id = mh.movie_id
GROUP BY ak.name, at.title
HAVING COUNT(ci.person_id) > 1 AND AVG(mh.hierarchy_level) < 3
ORDER BY avg_hierarchy_level DESC, actor_name;
