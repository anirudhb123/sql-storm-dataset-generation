WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
ranked_cast AS (
    SELECT 
        ci.movie_id, 
        ak.name, 
        ci.nr_order,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(SUM(CASE WHEN r.rank_order <= 3 THEN 1 ELSE 0 END), 0) AS top_cast_count,
    COALESCE(mis.info_count, 0) AS total_info_types,
    COALESCE(mis.info_details, 'No Info') AS info_details,
    CAST(mh.depth AS VARCHAR) || ' levels deep' AS hierarchy_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_cast r ON mh.movie_id = r.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mis.info_count, mis.info_details, mh.depth
ORDER BY 
    mh.production_year DESC, top_cast_count DESC;