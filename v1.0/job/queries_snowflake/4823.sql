WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        COALESCE(mo.movie_count, 0) AS movie_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS movie_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) mo ON rm.movie_id = mo.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.movie_count,
    CASE
        WHEN md.actor_count > 10 THEN 'Ensemble Cast'
        WHEN md.actor_count IS NULL THEN 'No Cast'
        ELSE 'Regular Cast'
    END AS cast_type
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC
LIMIT 50;
