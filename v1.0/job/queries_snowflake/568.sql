
WITH RankedMovies AS (
    SELECT 
        a.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        title a ON at.movie_id = a.id
    LEFT JOIN 
        cast_info c ON at.movie_id = c.movie_id
    GROUP BY 
        a.title, at.production_year
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
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    mc.company_name,
    mc.company_type,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.production_year = mi.movie_id
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = (SELECT a.id FROM title a WHERE a.title = tm.title LIMIT 1)
WHERE 
    tm.actor_count > 0
ORDER BY 
    tm.production_year DESC,
    tm.actor_count DESC;
