WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MoviesWithActorCounts AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorCounts ac ON r.title_id = ac.movie_id
)
SELECT 
    mwac.title,
    mwac.production_year,
    mwac.actor_count,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mwac.title_id) AS keyword_count,
    CASE 
        WHEN mwac.actor_count > 5 THEN 'Ensemble Cast'
        WHEN mwac.actor_count = 0 THEN 'No Actors'
        ELSE 'Regular Cast'
    END AS cast_type
FROM 
    MoviesWithActorCounts mwac
WHERE 
    mwac.actor_count IS NOT NULL
    AND mwac.production_year > 2000
ORDER BY 
    mwac.production_year DESC, 
    mwac.actor_count DESC
FETCH FIRST 10 ROWS ONLY;
