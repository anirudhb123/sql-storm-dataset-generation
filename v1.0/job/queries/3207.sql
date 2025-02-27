WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastWithRoles AS (
    SELECT 
        c.movie_id, 
        p.name AS actor_name,
        r.role AS role_name,
        c.nr_order 
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanyCTE AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(mcc.company_count, 0) AS company_count,
    mcc.companies,
    COUNT(DISTINCT cr.actor_name) AS actor_count,
    AVG(cr.nr_order) AS avg_order
FROM 
    RankedTitles rt
LEFT JOIN 
    CastWithRoles cr ON rt.title_id = cr.movie_id
LEFT JOIN 
    MovieCompanyCTE mcc ON rt.title_id = mcc.movie_id
GROUP BY 
    rt.title_id, rt.title, rt.production_year, mcc.company_count, mcc.companies
HAVING 
    COUNT(DISTINCT cr.actor_name) > 3 
    OR mcc.company_count IS NULL
ORDER BY 
    rt.production_year DESC, actor_count DESC;
