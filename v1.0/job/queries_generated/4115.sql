WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
TitleWithCompanyRoles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        cr.company_name,
        cr.company_type,
        cr.total_companies
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyRoles cr ON rt.title_id = cr.movie_id
)
SELECT 
    twcr.title,
    twcr.production_year,
    COALESCE(twcr.company_name, 'Unknown Company') AS company_name,
    twcr.company_type,
    MAX(twcr.total_companies) OVER (PARTITION BY twcr.production_year) AS max_companies,
    CASE 
        WHEN twcr.total_companies IS NULL THEN 'No Data'
        WHEN twcr.total_companies > 5 THEN 'Major Studio'
        ELSE 'Independent'
    END AS studio_status
FROM 
    TitleWithCompanyRoles twcr
WHERE 
    twcr.production_year BETWEEN 2000 AND 2020
ORDER BY 
    twcr.production_year DESC, twcr.title;
