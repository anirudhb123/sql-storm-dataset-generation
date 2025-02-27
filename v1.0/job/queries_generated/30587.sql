WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mh.level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    AVG(CASE WHEN cc.role_id IS NOT NULL THEN 1 ELSE 0 END) * 100 AS role_percentage,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    COALESCE(mm.info, 'No Info') AS movie_info
FROM aka_name ak
JOIN cast_info cc ON ak.person_id = cc.person_id
JOIN movie_hierarchy mh ON mh.movie_id = cc.movie_id
JOIN aka_title mt ON mh.movie_id = mt.id
LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN keyword kt ON mk.keyword_id = kt.id
LEFT JOIN movie_info mm ON mt.id = mm.movie_id AND mm.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE mt.production_year > 1990
GROUP BY ak.name, mt.title, mt.production_year, mm.info
ORDER BY total_cast DESC, mt.production_year DESC
LIMIT 10;
