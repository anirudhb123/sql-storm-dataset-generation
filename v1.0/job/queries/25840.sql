WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        aka_name.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY title.production_year DESC) AS rank
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        company_name.country_code = 'USA'
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    STRING_AGG(rm.actor_name, ', ') AS actors
FROM 
    RankedMovies rm
WHERE 
    rm.rank = 1
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC;