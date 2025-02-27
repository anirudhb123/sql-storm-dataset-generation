WITH RankedMovies AS (
    SELECT 
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyInfo AS (
    SELECT 
        movie_companies.movie_id,
        company_name.name AS company_name,
        company_type.kind AS company_type
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
)

SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(STRING_AGG(ci.company_name || ' (' || ci.company_type || ')', ', '), 'No Companies') AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = cc.movie_id
LEFT JOIN 
    CompanyInfo ci ON cc.movie_id = ci.movie_id
GROUP BY 
    tm.title, tm.production_year, tm.actor_count
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
