
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MostFeaturedActors AS (
    SELECT 
        a.person_id,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.person_id
    HAVING 
        COUNT(*) > 5
),
MovieProductionCompanies AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title AS Movie_Title,
    rm.production_year AS Production_Year,
    COALESCE(ma.role_count, 0) AS Actor_Role_Count,
    COALESCE(mp.companies, 'No Companies') AS Production_Companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MostFeaturedActors ma ON rm.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ma.person_id LIMIT 1)
LEFT JOIN 
    MovieProductionCompanies mp ON rm.movie_id = mp.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    Actor_Role_Count DESC;
