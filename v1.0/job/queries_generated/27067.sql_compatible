
WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        rc.role AS character_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
    WHERE 
        mt.production_year >= 2000
    AND 
        ak.name IS NOT NULL
),

ActorMovieCount AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rank = 1
    GROUP BY 
        actor_name
    HAVING 
        COUNT(movie_title) >= 5
),

TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorMovieCount
),

FinalResults AS (
    SELECT 
        ta.actor_name,
        ta.movie_count,
        ARRAY_AGG(DISTINCT rm.movie_title) AS movies
    FROM 
        TopActors ta
    JOIN 
        RankedMovies rm ON ta.actor_name = rm.actor_name
    WHERE 
        ta.actor_rank <= 10
    GROUP BY 
        ta.actor_name, ta.movie_count
)

SELECT 
    actor_name,
    movie_count,
    movies
FROM 
    FinalResults
ORDER BY 
    movie_count DESC;
