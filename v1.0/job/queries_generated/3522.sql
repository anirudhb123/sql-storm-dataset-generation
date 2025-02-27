WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
        AND ak.name IS NOT NULL
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS movie_info
    FROM 
        movie_info mi 
    JOIN 
        RankedMovies rm ON mi.movie_id = rm.movie_id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
),
FilterMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        CASE 
            WHEN rm.actor_rank = 1 THEN 'Lead Actor'
            ELSE 'Supporting Actor'
        END AS role_type,
        COALESCE(mi.movie_info, 'No Information Available') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    role_type,
    additional_info
FROM 
    FilterMovies
WHERE 
    production_year IS NOT NULL
ORDER BY 
    production_year DESC, movie_title ASC;
