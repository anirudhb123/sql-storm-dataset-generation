WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           1 AS level,
           NULL AS parent_movie_id
    FROM aka_title mt
    WHERE mt.kind_id IN (1, 2, 3)  -- Selecting specific kinds like 'movie', 'series', 'short'

    UNION ALL

    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mh.level + 1 AS level,
           mh.movie_id AS parent_movie_id
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ah.id AS actor_id,
    ak.name AS actor_name,
    COUNT(DISTINCT m.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    SUM(CASE 
            WHEN m.kind_id = 1 THEN 1
            ELSE 0 
        END) AS feature_film_count,
    SUM(CASE 
            WHEN m.kind_id = 2 THEN 1 
            ELSE 0 
        END) AS series_count,
    MAX(mh.level) AS max_link_level
FROM aka_name ak
JOIN cast_info ci ON ci.person_id = ak.person_id
JOIN title mt ON mt.id = ci.movie_id
LEFT JOIN movie_hierarchy mh ON mh.movie_id = mt.id
JOIN aka_title m ON m.id = mt.id
WHERE ak.name IS NOT NULL
GROUP BY ak.id, ak.name
HAVING COUNT(DISTINCT m.movie_id) > 5
ORDER BY avg_production_year DESC;
