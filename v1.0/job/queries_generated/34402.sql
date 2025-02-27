WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT mt.id, mt.title, mt.production_year, mh.level + 1
    FROM aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),

cast_with_roles AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        rt.role AS role_name,
        COUNT(ci.id) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),

movie_info_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY_AGG(mk.keyword) AS keywords,
        ROUND(AVG(mvi.info::NUMERIC), 2) AS avg_rating
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN movie_info mvi ON mt.id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY mt.id
)

SELECT 
    mh.title,
    mh.production_year,
    cr.actor_name,
    cr.role_name,
    COALESCE(mk.keywords, '{}') AS keywords,
    COALESCE(mk.avg_rating, 'N/A') AS average_rating,
    CASE 
        WHEN cr.actor_count > 5 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_size_category
FROM movie_hierarchy mh
JOIN cast_with_roles cr ON mh.movie_id = cr.movie_id
LEFT JOIN movie_info_with_keywords mk ON mh.movie_id = mk.movie_id
WHERE mh.level < 3
ORDER BY mh.production_year DESC, mh.title, cr.role_name;
