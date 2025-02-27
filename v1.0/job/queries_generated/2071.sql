WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT cn.country_code) > 1
),
TitleRoleStats AS (
    SELECT 
        ct.kind AS role_type,
        COUNT(ci.person_id) AS actor_count,
        AVG(COALESCE(CAST(ci.nr_order AS FLOAT), 0)) AS avg_order
    FROM 
        cast_info ci
    JOIN 
        role_type ct ON ci.role_id = ct.id
    GROUP BY 
        ct.kind
)
SELECT 
    rt.title,
    rt.production_year,
    fc.company_names,
    tr.actor_count,
    tr.avg_order
FROM 
    RankedTitles rt
LEFT JOIN 
    FilteredCompanies fc ON rt.title_rank = 1 AND rt.production_year IN (SELECT DISTINCT production_year FROM filtered_companies WHERE company_count > 1)
LEFT JOIN 
    TitleRoleStats tr ON rt.production_year = (SELECT MAX(production_year) FROM RankedTitles WHERE title = rt.title)
WHERE 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, tr.actor_count DESC NULLS LAST;
