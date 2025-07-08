
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rnk
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        cr.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type cr ON ci.role_id = cr.id
    GROUP BY 
        ci.movie_id, cr.role
)
SELECT 
    r.title,
    r.production_year,
    COALESCE(mc.company_count, 0) AS total_companies,
    COALESCE(cr.role_count, 0) AS total_roles,
    CASE 
        WHEN cr.role IS NULL THEN 'No Roles'
        ELSE cr.role 
    END AS role_description
FROM 
    RankedTitles r
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = (SELECT t.id FROM aka_title t WHERE t.title = r.title LIMIT 1)
LEFT JOIN 
    CastRoles cr ON cr.movie_id = (SELECT t.id FROM aka_title t WHERE t.title = r.title LIMIT 1)
WHERE 
    r.rnk = 1
ORDER BY 
    r.production_year DESC, 
    total_companies DESC,
    role_description;
