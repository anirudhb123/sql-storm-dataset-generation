WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(dc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(dc.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info dc ON t.id = dc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(ci.companies, 'No Companies') AS companies,
    tm.cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCounts kc ON tm.title = (SELECT title FROM aka_title WHERE id = kc.movie_id)
LEFT JOIN 
    CompanyInfo ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
