WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
TopActors AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c 
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        c.note IS NULL
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
)
SELECT 
    rm.title, 
    rm.production_year, 
    ac.actor_count, 
    ta.actor_name, 
    ta.movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    TopActors ta ON ta.movie_count = ac.actor_count
WHERE 
    rm.rank_in_year <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC, 
    ac.actor_count DESC;
