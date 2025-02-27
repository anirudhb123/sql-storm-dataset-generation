WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(ci.company_count, 0) AS company_count,
    ci.companies
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyInfo ci ON tm.production_year = ci.movie_id
ORDER BY 
    tm.production_year DESC, 
    company_count DESC

