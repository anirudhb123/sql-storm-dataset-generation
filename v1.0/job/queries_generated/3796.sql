WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.id) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
MoviesAndRoles AS (
    SELECT 
        rm.title,
        rm.production_year,
        cr.role,
        cr.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles cr ON rm.id = cr.movie_id
    WHERE 
        rm.rank <= 10
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    mar.title,
    mar.production_year,
    mar.role,
    COALESCE(mar.actor_count, 0) AS actor_count,
    COALESCE(mi.info_details, 'No details available') AS info_details
FROM 
    MoviesAndRoles mar
LEFT JOIN 
    MovieInfo mi ON mar.production_year = mi.movie_id
WHERE 
    mar.production_year >= 2000
ORDER BY 
    mar.production_year DESC, mar.title;
