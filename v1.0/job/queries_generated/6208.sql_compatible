
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        aka_title a ON t.id = a.movie_id
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) >= 5
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    cd.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
ORDER BY 
    rm.actor_count DESC, 
    rm.production_year DESC
LIMIT 10;
