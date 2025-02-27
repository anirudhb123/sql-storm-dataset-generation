WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.production_year > 2000
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title, mh.level + 1
    FROM aka_title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, actor_info AS (
    SELECT a.id AS actor_id, ak.name, c.movie_id, 
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.id) AS actor_order
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN movie_companies mc ON mc.movie_id = c.movie_id
    WHERE mc.company_id IS NOT NULL
)
SELECT 
    mh.movie_id,
    mh.title,
    COALESCE(STRING_AGG(ai.name, ', '), 'No Cast') AS actor_names,
    COUNT(DISTINCT ai.actor_id) AS actor_count,
    MAX(CASE WHEN ai.actor_order = 1 THEN ai.name END) AS lead_actor,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(m.production_year) AS avg_production_year,
    CASE 
        WHEN COUNT(DISTINCT ai.actor_id) > 5 THEN 'Ensemble Cast' 
        ELSE 'Small Cast' 
    END AS cast_size_description
FROM movie_hierarchy mh
LEFT JOIN actor_info ai ON mh.movie_id = ai.movie_id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN title m ON mh.movie_id = m.id
WHERE m.production_year IS NOT NULL
GROUP BY mh.movie_id, mh.title
HAVING COUNT(DISTINCT mc.company_id) > 1
ORDER BY avg_production_year DESC, mh.title;
