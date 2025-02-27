WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
),
ActorMovieCount AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        actor_id
),
TopActors AS (
    SELECT 
        actor_id,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorMovieCount
    WHERE
        movie_count > 5
)
SELECT 
    ak.name AS actor_name,
    amc.movie_count,
    tm.movie_title,
    tm.production_year
FROM 
    TopActors ta
JOIN 
    ActorMovieCount amc ON ta.actor_id = amc.actor_id
JOIN 
    RankedMovies tm ON amc.actor_id = tm.actor_id
WHERE 
    ta.rank <= 10
ORDER BY 
    amc.movie_count DESC, tm.production_year DESC;

This query benchmarks string processing by analyzing movie titles and actor names in relation to their production years. It identifies the top actors based on the number of movies they've appeared in since the year 2000 and retrieves details about the most prolific actors along with their movie titles.
