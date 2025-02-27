WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
    FROM 
        title m
    WHERE 
        m.production_year > 2000
), 
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
), 
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.actor_count, 0) AS total_actors,
    COALESCE(cc.company_count, 0) AS total_companies,
    CASE 
        WHEN cd.actor_count IS NULL THEN 'No Cast'
        ELSE 'Cast Present'
    END AS cast_status
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyCount cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.year_rank <= 5 
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;