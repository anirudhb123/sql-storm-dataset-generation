WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id,
        e.title,
        mh.level + 1,
        mh.movie_id
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mo.info, ', ') AS all_info,
        COUNT(mi.id) AS info_count
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx mo ON mi.movie_id = mo.movie_id
    GROUP BY 
        mi.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS unique_cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(cs.distinct_cast_count, 0) AS cast_count,
        mis.all_info,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY COALESCE(cs.distinct_cast_count, 0) DESC) AS movie_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        movie_info_summary mis ON mh.movie_id = mis.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.cast_count,
    r.all_info,
    CASE 
        WHEN r.cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status,
    COALESCE(NULLIF(r.movie_rank, 0), 'N/A') AS rank_with_fallback
FROM 
    ranked_movies r
WHERE 
    r.cast_count > 0
ORDER BY 
    r.movie_rank;
