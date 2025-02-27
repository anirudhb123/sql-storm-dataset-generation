WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRankedTitles AS (
    SELECT 
        rt.title_id, 
        rt.title, 
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MoviesWithCompanyInfo AS (
    SELECT 
        tt.title, 
        tt.production_year, 
        mc.company_names, 
        mc.company_types
    FROM 
        TopRankedTitles tt
    LEFT JOIN 
        MovieCompanies mc ON tt.title_id = mc.movie_id
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(m.company_names, 'No Companies') AS Companies_Involved,
    COALESCE(m.company_types, 'No Types') AS Company_Types
FROM 
    MoviesWithCompanyInfo m
WHERE 
    m.production_year > 2000 
    AND (m.company_names IS NULL OR m.company_types IS NOT NULL)
ORDER BY 
    m.production_year DESC, 
    LENGTH(m.Movie_Title);
