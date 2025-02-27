WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC) AS rn
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        cast_info.movie_id,
        COUNT(DISTINCT cast_info.person_id) AS actor_count
    FROM 
        cast_info
    GROUP BY 
        cast_info.movie_id
),
MoviesWithActorCount AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(amc.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovieCount amc ON rm.movie_id = amc.movie_id
)
SELECT 
    mwac.title,
    mwac.production_year,
    mwac.actor_count,
    CASE 
        WHEN mwac.actor_count > 5 THEN 'Popular'
        WHEN mwac.actor_count = 0 THEN 'No Cast'
        ELSE 'Moderate'
    END AS cast_category,
    (SELECT STRING_AGG(DISTINCT ak.name, ', ') 
     FROM aka_title at 
     JOIN aka_name ak ON at.id = ak.id 
     WHERE at.movie_id = mwac.movie_id) AS aliases
FROM 
    MoviesWithActorCount mwac 
WHERE 
    mwac.production_year >= 2000
ORDER BY 
    mwac.production_year DESC, mwac.actor_count DESC;
