WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ar.role_count, 0) AS role_count,
        ar.actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.role_count,
    mwc.actor_names,
    CASE 
        WHEN mwc.role_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_presence,
    CONCAT(mwc.title, ' (', mwc.production_year, ')') AS title_with_year
FROM 
    MoviesWithCast mwc
WHERE 
    mwc.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mwc.production_year DESC, mwc.title ASC
LIMIT 100;