WITH RecentMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id DESC) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2020
),
Actors AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.person_id, ka.name
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS companies_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT mc.company_id) > 1
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    a.name AS actor_name,
    COALESCE(c.company_count, 0) AS company_count,
    a.movie_count AS actor_movie_count
FROM 
    RecentMovies rm
LEFT JOIN 
    CompanyMovieInfo c ON rm.movie_id = c.movie_id
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    Actors a ON ci.person_id = a.person_id
WHERE 
    rm.rn = 1
    AND (c.companies_count IS NULL OR c.companies_count > 2)
    AND (rm.production_year IS NOT NULL AND rm.production_year > 2019)
ORDER BY 
    rm.production_year DESC, 
    a.movie_count DESC;
