WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(r.role) AS lead_role
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.company_name,
    cd.company_type,
    cr.total_cast,
    cr.lead_role
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyData cd ON rt.production_year = cd.movie_id
LEFT JOIN 
    CastRoles cr ON rt.production_year = cr.movie_id
WHERE 
    rt.year_rank <= 3
ORDER BY 
    rt.production_year DESC, 
    cr.total_cast DESC NULLS LAST
LIMIT 10;
