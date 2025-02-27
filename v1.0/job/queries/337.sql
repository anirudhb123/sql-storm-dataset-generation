WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(am.actor_name, 'No Actor') AS actor_name,
    am.actor_count,
    (SELECT COUNT(*)
     FROM movie_keyword mk
     WHERE mk.movie_id = rm.movie_id) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovies am ON rm.movie_id = am.movie_id
WHERE 
    am.actor_count > 0 OR am.actor_name IS NULL
ORDER BY 
    rm.production_year DESC, rm.title;
