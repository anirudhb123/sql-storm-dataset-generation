WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.companies, 'No Companies') AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON tm.title_id = mc.movie_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
