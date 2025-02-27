WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS full_path
    FROM title m
    WHERE m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        CAST(mh.full_path || ' -> ' || e.title AS VARCHAR(255))
    FROM title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        STRING_AGG(aka.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name aka ON ci.person_id = aka.person_id
    GROUP BY ci.movie_id
),
distinct_movies AS (
    SELECT DISTINCT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(c.total_cast, 0) AS total_cast,
        COALESCE(c.cast_names, 'No Cast') AS cast_names
    FROM title m
    LEFT JOIN cast_stats c ON m.id = c.movie_id
),
movie_info_with_keywords AS (
    SELECT 
        dm.movie_id,
        dm.title,
        dm.production_year,
        dm.total_cast,
        dm.cast_names,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM distinct_movies dm
    LEFT JOIN movie_keyword mk ON dm.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
final_output AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mi.total_cast,
        mi.cast_names,
        mi.keyword,
        mh.level,
        CASE 
            WHEN mh.level = 0 THEN 'Main Movie'
            ELSE 'Sub Movie Level ' || mh.level
        END AS movie_category
    FROM movie_hierarchy mh
    JOIN movie_info_with_keywords mi ON mh.movie_id = mi.movie_id
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.total_cast,
    fo.cast_names,
    fo.keyword,
    fo.movie_category,
    ROW_NUMBER() OVER (PARTITION BY fo.production_year ORDER BY fo.total_cast DESC) AS rank_within_year
FROM final_output fo
WHERE fo.total_cast > 0
ORDER BY fo.production_year DESC, fo.total_cast DESC;
