WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        sub_mt.title,
        sub_mt.production_year,
        sub_mt.kind_id,
        h.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy h ON ml.movie_id = h.movie_id
    JOIN aka_title sub_mt ON ml.linked_movie_id = sub_mt.id
),

cast_roles AS (
    SELECT 
        ci.movie_id,
        ci.role_id,
        COUNT(*) AS role_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id, ci.role_id
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    m.movie_title,
    m.production_year,
    m.level,
    cr.role_count,
    cr.actor_names,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords
FROM movie_hierarchy m
LEFT JOIN cast_roles cr ON m.movie_id = cr.movie_id
LEFT JOIN movie_keywords mk ON m.movie_id = mk.movie_id
WHERE m.level = 1 
AND (m.kind_id IS NOT NULL OR m.production_year IS NOT NULL) 
ORDER BY m.production_year DESC, m.movie_title;

This SQL query creates a recursive Common Table Expression (CTE) to construct a hierarchy of movies linked through movie relationships established in the `movie_link` table, focusing on movies produced after 2000. It then gathers cast roles with their associated counts and actor names from the `cast_info` and `aka_name` tables. Additionally, it aggregates keywords for the movies from the `movie_keyword` table while handling cases of missing keywords with a `COALESCE` function. Finally, the main SELECT statement retrieves and organizes this information, ensuring it only lists the top-level movies in the hierarchy and orders them by production year and title.
