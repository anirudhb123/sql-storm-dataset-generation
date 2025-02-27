WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info ca
    GROUP BY 
        ca.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        am.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
    WHERE 
        rm.rank <= 5 OR am.actor_count IS NULL
),
MovieInfo AS (
    SELECT 
        fm.movie_id,
        STRING_AGG(mi.info, '; ') AS all_info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON fm.movie_id = mi.movie_id
    GROUP BY 
        fm.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mi.all_info, 'No info available') AS movie_info_summary,
    CASE 
        WHEN fm.actor_count IS NOT NULL THEN 
            CONCAT('This movie features ', fm.actor_count, ' actors.')
        ELSE 
            'This movie has no recorded actors.'
    END AS actor_details
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieInfo mi ON fm.movie_id = mi.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.title;
