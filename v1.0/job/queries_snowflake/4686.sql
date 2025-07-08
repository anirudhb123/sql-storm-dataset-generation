
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles_played
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
),
MoviesWithActorCount AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.movie_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoleCounts ac ON rm.movie_id = ac.person_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    mw.title,
    mw.production_year,
    mw.actor_count,
    CASE 
        WHEN mw.actor_count = 0 THEN 'No actors'
        ELSE 'Actors present'
    END AS actor_status
FROM 
    MoviesWithActorCount mw
WHERE 
    mw.actor_count IS NOT NULL
ORDER BY 
    mw.production_year DESC, mw.actor_count DESC
LIMIT 10;
