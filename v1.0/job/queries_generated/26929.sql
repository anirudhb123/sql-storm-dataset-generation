WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY CAST(ci.nr_order AS INTEGER)) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        mt.production_year >= 2000
),
ActorMovieCounts AS (
    SELECT 
        actor_name, 
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
),
HighProfileActors AS (
    SELECT 
        actor_name
    FROM 
        ActorMovieCounts
    WHERE 
        movie_count > 5
),
MoviesWithHighProfileActors AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name
    FROM 
        RankedMovies rm
    JOIN 
        HighProfileActors hpa ON rm.actor_name = hpa.actor_name
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT a.name) AS unique_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_list
FROM 
    title m
JOIN 
    MoviesWithHighProfileActors mwa ON m.title = mwa.movie_title AND m.production_year = mwa.production_year
JOIN 
    aka_name a ON mwa.actor_name = a.name
GROUP BY 
    m.title, m.production_year
ORDER BY 
    unique_actors DESC, m.production_year DESC;
