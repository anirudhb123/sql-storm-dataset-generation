WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*)
        OVER (PARTITION BY t.production_year) AS total_count
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieWithActors AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.title_id = ac.movie_id
    WHERE 
        rm.rn <= 5
)
SELECT 
    mw.title,
    mw.production_year,
    COALESCE(mw.actor_count, 0) AS actor_count,
    CASE 
        WHEN mw.actor_count IS NULL THEN 'No actors'
        WHEN mw.actor_count > 10 THEN 'Ensemble cast'
        ELSE 'Few actors'
    END AS cast_description
FROM 
    MovieWithActors mw
ORDER BY 
    mw.production_year DESC, mw.title;
