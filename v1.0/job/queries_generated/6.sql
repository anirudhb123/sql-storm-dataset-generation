WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ci.person_id,
        ka.name AS actor_name,
        RANK() OVER (PARTITION BY rm.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    WHERE 
        ka.name IS NOT NULL
),
MoviesWithInfo AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM 
        MoviesWithCast mwc
    LEFT JOIN 
        movie_info mi ON mwc.movie_id = mi.movie_id
    GROUP BY 
        mwc.movie_id, mwc.title, mwc.production_year
),
MovieSummary AS (
    SELECT 
        mw.title,
        mw.production_year,
        COUNT(DISTINCT mw.actor_name) AS actor_count,
        MAX(mw.actor_rank) AS max_actor_rank,
        COALESCE(mw.movie_info, 'No additional info') AS info_summary
    FROM 
        MoviesWithInfo mw
    GROUP BY 
        mw.title, mw.production_year
)
SELECT 
    mv.title,
    mv.production_year,
    mv.actor_count,
    mv.max_actor_rank,
    mv.info_summary
FROM 
    MovieSummary mv
WHERE 
    mv.actor_count > 2
ORDER BY 
    mv.production_year DESC, 
    mv.actor_count DESC;
