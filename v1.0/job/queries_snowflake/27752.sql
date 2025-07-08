WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL 
        AND a.name IS NOT NULL
),

ActorStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count,
        AVG(production_year) AS avg_year
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
),

TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        avg_year,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorStats
)

SELECT 
    ta.actor_name,
    ta.movie_count,
    ta.avg_year,
    (SELECT AVG(movie_count) FROM TopActors) AS average_movies_per_actor
FROM 
    TopActors ta
WHERE 
    ta.rank <= 10
ORDER BY 
    ta.movie_count DESC;
