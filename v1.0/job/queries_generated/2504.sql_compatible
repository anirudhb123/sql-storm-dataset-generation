
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
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
        rt.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
TitleStats AS (
    SELECT 
        rt.production_year,
        COUNT(rt.title_id) AS title_count,
        MAX(rt.title) AS latest_title
    FROM 
        RankedTitles rt
    GROUP BY 
        rt.production_year
)
SELECT 
    ts.production_year,
    ts.title_count,
    ts.latest_title,
    COALESCE(mc.company_count, 0) AS company_count,
    COALESCE(cr.role_count, 0) AS actor_count
FROM 
    TitleStats ts
LEFT JOIN 
    MovieCompanies mc ON ts.latest_title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    CastRoles cr ON mc.movie_id = cr.movie_id
ORDER BY 
    ts.production_year DESC, 
    ts.title_count DESC
LIMIT 100;
