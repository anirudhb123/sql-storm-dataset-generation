WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        ri.role AS role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type ri ON ci.role_id = ri.id
    WHERE 
        ci.note IS NULL
    GROUP BY 
        ci.movie_id, ri.role
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(mi.info) AS latest_info
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
),
FinalResults AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        mc.company_count,
        mc.company_names,
        pr.role,
        pr.role_count,
        mi.latest_info
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieCompanies mc ON rt.title_id = mc.movie_id
    LEFT JOIN 
        PersonRoles pr ON rt.title_id = pr.movie_id
    LEFT JOIN 
        MovieInfo mi ON rt.title_id = mi.movie_id
    WHERE 
        (mc.company_count > 1 OR pr.role_count > 2)
        AND rt.rank = 1
)
SELECT 
    title,
    production_year,
    COALESCE(company_names, 'No companies') AS company_names,
    COALESCE(role, 'No roles') AS role,
    COALESCE(role_count, 0) AS role_count,
    COALESCE(latest_info, 'No info available') AS latest_info 
FROM 
    FinalResults
ORDER BY 
    production_year DESC, title;
