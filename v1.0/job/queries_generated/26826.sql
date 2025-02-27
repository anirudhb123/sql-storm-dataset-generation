WITH ActorMovieCounts AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
), 
PopularMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) >= 5
), 
DetailedMovieInfo AS (
    SELECT 
        mt.title AS movie_title,
        p.actor_name,
        p.movie_count,
        mt.production_year
    FROM 
        PopularMovies pm
    JOIN 
        actorMovieCounts p ON p.movie_count > 2
    JOIN 
        aka_title mt ON pm.movie_title = mt.title
    WHERE 
        mt.production_year = p.production_year
)
SELECT 
    dmi.movie_title,
    dmi.production_year,
    dmi.actor_name,
    dmi.movie_count
FROM 
    DetailedMovieInfo dmi
ORDER BY 
    dmi.production_year DESC, 
    dmi.actor_name ASC;
