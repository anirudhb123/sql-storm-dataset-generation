WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id ASC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS role_type,
        COUNT(*) AS num_roles
    FROM 
        cast_info ci
    INNER JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
)

SELECT 
    rt.title,
    rt.production_year,
    COALESCE(mc.company_name, 'Unknown') AS company,
    COALESCE(mr.role_type, 'No Role Assigned') AS role,
    rk.num_roles,
    CASE 
        WHEN rt.production_year < 2000 THEN 'Classic'
        WHEN rt.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieCompanies mc ON rt.id = mc.movie_id AND mc.company_rank = 1
LEFT JOIN 
    CastRoles mr ON rt.id = mr.movie_id
LEFT JOIN 
    (SELECT movie_id, SUM(num_roles) AS num_roles FROM CastRoles GROUP BY movie_id) rk ON rt.id = rk.movie_id
WHERE
    rt.rank_per_year <= 10
ORDER BY 
    rt.production_year DESC, rt.title ASC;
