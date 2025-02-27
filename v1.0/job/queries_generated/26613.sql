WITH ActorTitles AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year AS year 
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name LIKE '%Smith%'  -- Benchmark for string matching
),
PopularMovies AS (
    SELECT 
        mt.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count 
    FROM 
        movie_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.movie_id
    HAVING 
        COUNT(DISTINCT ci.person_id) >= 5  -- Popular movies with at least 5 actors
),
MovieDetails AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        GROUP_CONCAT(DISTINCT a.actor_name ORDER BY a.actor_name ASC) AS actors 
    FROM 
        PopularMovies pm
    JOIN 
        aka_title mt ON pm.movie_id = mt.id
    JOIN 
        ActorTitles a ON a.movie_title = mt.title
    GROUP BY 
        mt.title, mt.production_year
)
SELECT 
    title, 
    production_year, 
    actors 
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, 
    title ASC;
