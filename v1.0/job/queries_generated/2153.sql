WITH movie_stats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        COALESCE(SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
top_roles AS (
    SELECT 
        movie_id,
        role,
        role_count,
        RANK() OVER (PARTITION BY movie_id ORDER BY role_count DESC) as rk
    FROM 
        cast_roles
),
keyword_summary AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.cast_count,
    ms.info_count,
    ms.keyword_count,
    COALESCE(tr.role, 'No Role') AS top_role,
    COALESCE(tr.role_count, 0) AS top_role_count,
    ks.keywords
FROM 
    movie_stats ms
LEFT JOIN 
    top_roles tr ON ms.movie_id = tr.movie_id AND tr.rk = 1
LEFT JOIN 
    keyword_summary ks ON ms.movie_id = ks.movie_id
WHERE 
    ms.cast_count > 0
ORDER BY 
    ms.cast_count DESC, ms.movie_id;

