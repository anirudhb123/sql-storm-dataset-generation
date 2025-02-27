WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank_within_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyMovies AS (
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
        MAX(rt.role) AS main_role
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
ComprehensiveMovieInfo AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(cm.company_name, 'No Company') AS production_company,
        COALESCE(cr.total_cast, 0) AS total_cast,
        COALESCE(cr.main_role, 'Unknown Role') AS main_role,
        COALESCE(ki.keyword, 'No Keyword') AS keyword
    FROM 
        RankedTitles t
    LEFT JOIN 
        CompanyMovies cm ON t.id = cm.movie_id
    LEFT JOIN 
        CastRoles cr ON t.id = cr.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
)
SELECT 
    title, 
    production_year,
    production_company,
    total_cast,
    main_role,
    keyword
FROM 
    ComprehensiveMovieInfo
WHERE 
    total_cast > 10 OR (production_year = 2020 AND main_role IS NOT NULL)
ORDER BY 
    production_year DESC, 
    title ASC
FETCH FIRST 100 ROWS ONLY;
