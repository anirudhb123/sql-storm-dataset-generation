WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
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
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(mc.companies, 'No companies') AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON tm.movie_id = mc.movie_id
)
SELECT 
    title, 
    production_year, 
    cast_count, 
    keywords, 
    companies
FROM 
    FinalResults
ORDER BY 
    production_year DESC, cast_count DESC;
