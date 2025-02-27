WITH movie_keywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword, 
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
movie_info_with_comp AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        COALESCE(COUNT(mc.company_id), 0) AS company_count,
        COALESCE(MAX(mi.info), 'No info') AS latest_info
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
),
cast_roles AS (
    SELECT 
        c.movie_id, 
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
final_benchmark AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        mk.keyword,
        m.company_count,
        m.latest_info,
        cr.role,
        cr.role_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY cr.role_count DESC) AS role_order
    FROM 
        title t
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id AND mk.keyword_rank <= 3
    LEFT JOIN 
        movie_info_with_comp m ON t.id = m.movie_id
    LEFT JOIN 
        cast_roles cr ON t.id = cr.movie_id
)
SELECT 
    *,
    CASE 
        WHEN role_count IS NULL THEN 'No roles available'
        ELSE 'Role count available'
    END AS role_status
FROM 
    final_benchmark
WHERE 
    (production_year >= 2000 AND company_count > 2) OR (keyword IS NOT NULL)
ORDER BY 
    production_year DESC, role_count DESC;
