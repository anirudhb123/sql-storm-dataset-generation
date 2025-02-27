WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mh.depth + 1
    FROM aka_title mt
    INNER JOIN movie_link ml ON mt.id = ml.linked_movie_id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.depth < 5 
),

cast_details AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),

popular_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        cd.actor_count,
        cd.actor_names
    FROM movie_hierarchy mh
    LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
    WHERE mh.depth = 1 
        AND cd.actor_count > 3
        AND mh.production_year IS NOT NULL
)

SELECT
    pm.title,
    pm.production_year,
    pm.actor_count,
    COALESCE(pm.actor_names, 'No actors listed') AS actor_names,
    CASE 
        WHEN pm.production_year < 2010 THEN 'Classic'
        WHEN pm.production_year BETWEEN 2010 AND 2015 THEN 'Recent'
        ELSE 'New'
    END AS movie_category
FROM popular_movies pm
WHERE pm.actor_count IS NOT NULL
ORDER BY pm.production_year DESC
LIMIT 20;