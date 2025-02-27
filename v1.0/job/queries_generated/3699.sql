WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        kt.kind
    FROM 
        RankedMovies rm
    JOIN 
        kind_type kt ON rm.kind_id = kt.id
    WHERE 
        rm.rn <= 5
),
MoviesWithActors AS (
    SELECT 
        tm.title,
        tm.production_year,
        a.name AS actor_name,
        COUNT(ci.person_id) AS actor_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.title = cc.subject_id
    LEFT JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        tm.title, tm.production_year, a.name
)
SELECT 
    mw.title,
    mw.production_year,
    mw.actor_name,
    mw.actor_count,
    COALESCE(mw.actor_count, 0) AS valid_actor_count,
    CASE 
        WHEN mw.actor_count IS NULL THEN 'No Actors'
        ELSE 'Has Actors'
    END AS actor_presence
FROM 
    MoviesWithActors mw
ORDER BY 
    mw.production_year DESC, mw.actor_count DESC;
