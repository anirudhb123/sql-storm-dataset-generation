WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE mh.level < 3
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS lead_role_count,
        STRING_AGG(aka.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name aka ON aka.person_id = ci.person_id
    GROUP BY ci.movie_id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.lead_role_count,
        cs.cast_names,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.total_cast DESC) AS rank
    FROM movie_hierarchy mh
    JOIN cast_summary cs ON mh.movie_id = cs.movie_id
    WHERE mh.production_year > 2000 AND cs.lead_role_count > 1
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.lead_role_count,
    fm.cast_names,
    COALESCE(CAST(ROUND(AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END), 2) AS NUMERIC), 0) AS avg_info_length
FROM filtered_movies fm
LEFT JOIN movie_info mi ON fm.movie_id = mi.movie_id
GROUP BY fm.movie_id, fm.title, fm.production_year, fm.total_cast, fm.lead_role_count, fm.cast_names
HAVING COUNT(DISTINCT mi.info_type_id) > 2
ORDER BY fm.production_year DESC, fm.total_cast DESC
LIMIT 10
OFFSET 5;