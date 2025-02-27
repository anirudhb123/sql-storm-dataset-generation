WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mt.linked_movie_id,
        lt.title,
        mh.level + 1
    FROM 
        movie_link mt
    JOIN 
        title lt ON lt.id = mt.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = mt.movie_id
),
movie_info_combined AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS combined_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        MAX(ct.kind) AS most_common_role
    FROM 
        cast_info c
    JOIN 
        role_type ct ON ct.id = c.role_id
    GROUP BY 
        c.movie_id
),
final_benchmark AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COALESCE(mic.combined_info, 'No Info') AS info_summary,
        COALESCE(cs.total_cast, 0) AS total_cast,
        cs.most_common_role
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_info_combined mic ON mic.movie_id = mh.movie_id
    LEFT JOIN 
        cast_summary cs ON cs.movie_id = mh.movie_id
)
SELECT 
    fb.movie_id,
    fb.movie_title,
    fb.info_summary,
    fb.total_cast,
    fb.most_common_role,
    COUNT(*) OVER () AS total_movies_benchmark
FROM 
    final_benchmark fb
WHERE 
    fb.total_cast > 5 OR fb.info_summary LIKE '%Oscar%'
ORDER BY 
    fb.total_cast DESC, 
    fb.movie_title ASC
LIMIT 100;
