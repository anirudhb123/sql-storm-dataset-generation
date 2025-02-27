WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id, 
        0 AS depth  
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL

    SELECT 
        mc.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id, 
        mh.depth + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title at ON mc.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = mc.movie_id
    WHERE 
        mh.depth < 10
    AND 
        AT.production_year IS NOT NULL
),
cast_role_counts AS (
    SELECT 
        ci.movie_id, 
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_summary
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
title_keyword AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt 
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
)
SELECT 
    mh.title,
    mh.production_year,
    ti.info_summary,
    tr.role,
    tr.role_count,
    tk.keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_info_summary ti ON mh.movie_id = ti.movie_id
LEFT JOIN 
    cast_role_counts tr ON mh.movie_id = tr.movie_id
LEFT JOIN 
    title_keyword tk ON mh.movie_id = tk.movie_id
WHERE 
    mh.depth = 0 
    AND mh.production_year IS NOT NULL
    AND (tr.role_count > 1 OR tr.role IS NULL)
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC;