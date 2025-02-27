WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_cast
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        title_id, title, production_year, cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_cast <= 3
), 
CompanyMovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        m.movie_id
)

SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count,
    COALESCE(cmi.companies, 'No Companies') AS companies,
    COALESCE(cmi.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovieInfo cmi ON tm.title_id = cmi.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
