WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        COUNT(DISTINCT mk.keyword_id) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.production_companies,
    md.keywords,
    COALESCE(NULLIF(md.production_companies, 0), 'No Companies') AS company_info,
    CONCAT('Movie ', md.title, ' from ', md.production_year, ' has ', md.keywords, ' keywords.') AS movie_summary
FROM 
    MovieDetails md
WHERE 
    (md.keywords > 0 OR md.production_companies = 0)
ORDER BY 
    md.production_year DESC;
