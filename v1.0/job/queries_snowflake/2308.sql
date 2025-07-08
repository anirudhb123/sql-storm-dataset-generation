
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
company_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
actor_roles AS (
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
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(cc.company_count, 0) AS total_companies,
    COALESCE(arr.role_count, 0) AS current_role_count,
    mwk.keywords,
    CASE 
        WHEN rt.title_rank = 1 THEN 'Most Recent'
        ELSE 'Other'
    END AS title_category
FROM 
    ranked_titles rt
LEFT JOIN 
    company_counts cc ON rt.title_id = cc.movie_id
LEFT JOIN 
    actor_roles arr ON rt.title_id = arr.movie_id AND arr.role = 'Lead'
LEFT JOIN 
    movies_with_keywords mwk ON rt.title_id = mwk.movie_id
ORDER BY 
    rt.production_year DESC, rt.title;
