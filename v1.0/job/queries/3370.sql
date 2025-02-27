WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(*) AS cast_count
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
),
MoviesWithDetails AS (
    SELECT 
        tt.title,
        tt.production_year,
        mc.company_names,
        cc.cast_count
    FROM 
        TopTitles tt
    LEFT JOIN 
        MovieCompanies mc ON tt.title_id = mc.movie_id
    LEFT JOIN 
        CompleteCast cc ON tt.title_id = cc.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    COALESCE(mw.company_names, 'No Companies') AS companies,
    COALESCE(mw.cast_count, 0) AS total_cast
FROM 
    MoviesWithDetails mw
WHERE 
    mw.production_year > 2000
ORDER BY 
    mw.production_year DESC, mw.title;
