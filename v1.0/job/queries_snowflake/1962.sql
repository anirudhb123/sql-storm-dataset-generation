
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsMovies AS (
    SELECT 
        a.name AS actor_name,
        am.movie_id,
        am.title,
        am.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies am ON ci.movie_id = am.movie_id
    WHERE 
        am.rank <= 5
)
SELECT 
    COALESCE(actors.actor_name, 'Unknown Actor') AS actor,
    COUNT(am.movie_id) AS total_movies,
    LISTAGG(am.title, ', ') AS movies_list,
    MIN(am.production_year) AS first_movie_year,
    MAX(am.production_year) AS last_movie_year
FROM 
    ActorsMovies am
LEFT JOIN 
    (SELECT DISTINCT 
         a.name AS actor_name 
     FROM 
         aka_name a
     LEFT JOIN 
         cast_info ci ON a.person_id = ci.person_id
     WHERE 
         a.name IS NOT NULL) actors ON am.actor_name = actors.actor_name
GROUP BY 
    actors.actor_name
HAVING 
    COUNT(am.movie_id) > 1
ORDER BY 
    total_movies DESC;
