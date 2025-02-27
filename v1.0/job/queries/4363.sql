WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank,
    COALESCE(cr.actor_count, 0) AS actor_count,
    COALESCE(cr.cast_names, 'No Cast') AS cast_names,
    rm.company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles cr ON rm.movie_id = cr.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.rank ASC;
