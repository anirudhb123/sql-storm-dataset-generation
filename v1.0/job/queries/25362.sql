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