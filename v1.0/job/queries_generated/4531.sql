WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY COUNT(ci.person_id) DESC) AS role_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id
), 
ActorCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        an.name IS NOT NULL
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
), 
MovieWithActorCount AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    mw.title,
    mw.production_year,
    COALESCE(a.movie_count, 0) AS number_of_actors,
    rm.role_rank
FROM 
    MovieWithActorCount mw
LEFT JOIN 
    ActorCounts a ON mw.actor_count = a.movie_count
JOIN 
    RankedMovies rm ON mw.title = rm.title
WHERE 
    mw.production_year >= 2000
    AND (a.movie_count IS NOT NULL OR mw.actor_count > 10)
ORDER BY 
    mw.production_year DESC, rm.role_rank;
