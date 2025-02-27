WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT ml.linked_movie_id, at.title, at.production_year, mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movies,
    AVG(m.production_year) AS avg_production_year,
    SUM(CASE WHEN m.production_year IS NULL THEN 1 ELSE 0 END) AS null_year_count
FROM 
    aka_name ak
LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN aka_title m ON ci.movie_id = m.id
LEFT JOIN MovieHierarchy mh ON mh.movie_id = m.id
LEFT JOIN movie_companies mc ON m.id = mc.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_name
LIMIT 10;
