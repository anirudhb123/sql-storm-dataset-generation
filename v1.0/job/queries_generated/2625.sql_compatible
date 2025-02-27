
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rn
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN ActorCounts ac ON rm.movie_id = ac.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    COALESCE(mw.actor_count, 0) AS actor_count,
    REPLACE(mw.title, ' ', '-') AS title_slug,
    (SELECT 
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', ci.role_id, ')'), ', ')
     FROM 
        cast_info ci
     JOIN 
        aka_name a ON ci.person_id = a.person_id
     WHERE 
        ci.movie_id = mw.movie_id) AS actors
FROM 
    MovieWithActors mw
WHERE 
    COALESCE(mw.actor_count, 0) >= 5
ORDER BY 
    mw.production_year DESC, mw.title;
