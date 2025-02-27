WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id 
    WHERE mh.level < 5
)
SELECT 
    mv.movie_title,
    mv.production_year,
    CTE1.actor_name,
    CTE1.role_name,
    CASE 
        WHEN CTE1.note IS NULL THEN 'No Note' 
        ELSE CTE1.note 
    END AS actor_note,
    CASE 
        WHEN mv.production_year < 2000 THEN 'Classic' 
        ELSE 'Modern' 
    END AS movie_age_category,
    COUNT(DISTINCT mv.movie_id) OVER (PARTITION BY mv.production_year) AS total_movies_per_year
FROM movie_hierarchy mv
LEFT JOIN (
    SELECT 
        ci.movie_id,
        an.name AS actor_name,
        rt.role AS role_name,
        ci.note,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rn
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    WHERE an.name IS NOT NULL
) AS CTE1 
ON mv.movie_id = CTE1.movie_id 
WHERE mv.level = 1 -- Only get top-level movies
ORDER BY mv.production_year DESC, mv.movie_title, CTE1.actor_name
LIMIT 100;

-- Using set operations to fetch additional details
UNION ALL

SELECT 
    'Film Title Not Found' AS movie_title,
    NULL AS production_year,
    ci2.actor_name,
    ci2.role_name,
    'No Note' AS actor_note,
    NULL AS movie_age_category,
    COUNT(DISTINCT ci2.movie_id) OVER (PARTITION BY ci2.actor_name) AS total_movies_per_actor
FROM (
    SELECT 
        ci.movie_id, 
        an.name AS actor_name, 
        rt.role AS role_name, 
        ci.note 
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id 
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    WHERE an.name IS NULL
) AS ci2
WHERE ci2.note IS NOT NULL
ORDER BY total_movies_per_actor DESC;
