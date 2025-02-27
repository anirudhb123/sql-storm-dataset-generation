WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
        AND ak.name IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS movies
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_title) > 1
)
SELECT 
    actor_name,
    movie_count,
    movies
FROM 
    ActorMovieCounts
ORDER BY 
    movie_count DESC
LIMIT 10;

This SQL query benchmarks string processing by generating a ranked list of actors based on their appearances in movies produced since the year 2000. It first gathers movie titles, production years, company names, and actor names. Then, it counts the number of distinct movies for each actor and concatenates the titles into a single string. Finally, it selects the top 10 actors with more than one movie, ordering the results by the number of movies they appeared in.
