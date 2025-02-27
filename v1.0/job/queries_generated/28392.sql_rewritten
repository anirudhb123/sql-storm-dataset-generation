WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
), ActorMovieCounts AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS movie_list
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
), TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        movie_list,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorMovieCounts
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    ta.movie_list
FROM 
    TopActors ta
WHERE 
    ta.actor_rank <= 10
ORDER BY 
    ta.movie_count DESC;