WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM title m
    WHERE m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.depth + 1
    FROM title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        RANK() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank_per_depth
    FROM movie_hierarchy mh
),
cast_info_enriched AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON a.person_id = ci.person_id
    GROUP BY ci.movie_id
),
movies_with_cast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(c.total_cast, 0) AS total_cast,
        COALESCE(c.cast_names, 'No Cast') AS cast_names,
        rm.depth,
        rm.rank_per_depth
    FROM ranked_movies rm
    LEFT JOIN cast_info_enriched c ON rm.movie_id = c.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.total_cast,
    mwc.cast_names,
    mwc.depth,
    mwc.rank_per_depth
FROM movies_with_cast mwc
WHERE mwc.total_cast > 0
ORDER BY mwc.depth, mwc.rank_per_depth
LIMIT 100;

-- Additional performance benchmarks can include:
-- 1. Analyzing the runtime execution plans.
-- 2. Database resource utilization (CPU, memory).
-- 3. Execution time comparisons for varying dataset sizes.
-- 4. Examining results with and without indices.

