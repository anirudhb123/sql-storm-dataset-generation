
WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.movie_id) AS cast_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        a.id, a.name, t.title, t.production_year
    HAVING 
        COUNT(ci.movie_id) > 1
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.aka_name,
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    mc.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanies mc ON rm.aka_id = mc.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
