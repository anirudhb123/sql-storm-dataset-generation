WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) as rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
ActorMovieCounts AS (
    SELECT 
        a.name, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    amc.name AS top_actor,
    amc.movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovieCounts amc ON amc.movie_count = (SELECT MAX(movie_count) FROM ActorMovieCounts)
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC
LIMIT 10;
