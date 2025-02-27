WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM movie_link m
    JOIN aka_title m2 ON m.linked_movie_id = m2.id
    JOIN movie_hierarchy mh ON m.movie_id = mh.movie_id
    WHERE mh.level < 5 
)

SELECT 
    ak.name AS actor_name,
    mk.keyword AS movie_keyword,
    th.title AS movie_title,
    th.production_year,
    CASE 
        WHEN LENGTH(ak.name) > 16 THEN LEFT(ak.name, 16) || '...' 
        ELSE ak.name 
    END AS display_name,
    COUNT(DISTINCT mh.movie_id) OVER (PARTITION BY ak.id) AS num_of_linked_movies,
    COALESCE(SUM(mo.info IS NOT NULL)::integer, 0) AS non_null_info_count
FROM aka_name ak
JOIN cast_info ci ON ci.person_id = ak.person_id
JOIN movie_companies mc ON ci.movie_id = mc.movie_id
JOIN aka_title th ON th.id = ci.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = th.id
LEFT JOIN movie_info mo ON mo.movie_id = th.id AND mo.info_type_id = (
    SELECT id FROM info_type WHERE info = 'description'
    LIMIT 1
)
LEFT JOIN movie_hierarchy mh ON mh.movie_id = th.id
WHERE ak.name IS NOT NULL 
  AND ak.name NOT LIKE '%[0-9]%' 
GROUP BY 
    ak.id, mk.keyword, th.id
HAVING 
    COUNT(th.id) > 2 
    AND COALESCE(SUM(mo.note IS NOT NULL)::integer, 0) > 0 
ORDER BY 
    display_name ASC, 
    num_of_linked_movies DESC, 
    th.production_year DESC
LIMIT 100;
