
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS movie_rank,
        COUNT(c.person_id) AS actor_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.movie_rank <= 5
),
ActorCounts AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    ac.name AS top_actor,
    ac.movie_count
FROM 
    TopMovies tm
LEFT JOIN 
    ActorCounts ac ON ac.movie_count = tm.actor_count
WHERE 
    tm.actor_count > 2
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC
LIMIT 10;
