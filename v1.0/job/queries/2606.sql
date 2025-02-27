
WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.title, title.production_year, title.id
), 
RecentMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_count 
    FROM 
        RankedMovies 
    WHERE 
        production_year >= (SELECT MAX(production_year) - 10 FROM title)
),
CompanyMovieCounts AS (
    SELECT 
        movie_companies.movie_id,
        COUNT(DISTINCT company_name.id) AS company_count
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    WHERE 
        company_name.country_code IS NOT NULL
    GROUP BY 
        movie_companies.movie_id
)
SELECT 
    r.movie_title,
    r.production_year,
    r.actor_count,
    COALESCE(c.company_count, 0) AS company_count
FROM 
    RecentMovies r
LEFT JOIN 
    CompanyMovieCounts c ON r.movie_title = (SELECT title.title FROM title WHERE id = c.movie_id)
WHERE 
    r.actor_count > 2
ORDER BY 
    r.production_year DESC, r.actor_count DESC
LIMIT 10;
