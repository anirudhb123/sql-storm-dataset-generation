WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role AS role_name,
        COUNT(ci.id) AS total_roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(c.company_count, 0) AS company_count,
        COALESCE(cr.total_roles, 0) AS total_roles
    FROM 
        aka_title t
    LEFT JOIN 
        CompanyCount c ON t.id = c.movie_id
    LEFT JOIN 
        CastRoles cr ON t.id = cr.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.total_roles,
    COUNT(DISTINCT CAST(ci.id AS VARCHAR)) FILTER (WHERE ci.note IS NOT NULL) AS non_null_cast_count
FROM 
    MovieDetails md
LEFT JOIN 
    complete_cast ci ON md.movie_id = ci.movie_id
WHERE 
    md.company_count > 0
GROUP BY 
    md.title, md.production_year, md.company_count, md.total_roles
HAVING 
    COUNT(ci.id) > 1
ORDER BY 
    md.production_year DESC, md.title ASC;
