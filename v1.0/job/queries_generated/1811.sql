WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND a.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) as actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
MoviesWithActorCount AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.id = ac.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    mwac.title,
    mwac.production_year,
    COALESCE(mwac.actor_count, 0) AS actor_count,
    CASE 
        WHEN mwac.actor_count > 10 THEN 'Popular'
        WHEN mwac.actor_count IS NULL THEN 'No Actors'
        ELSE 'Moderate'
    END AS popularity_status
FROM 
    MoviesWithActorCount mwac
ORDER BY 
    mwac.production_year DESC, 
    mwac.actor_count DESC;
