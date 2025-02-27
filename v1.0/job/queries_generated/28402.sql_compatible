
WITH ActorMovies AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id AS actor_id,
        ti.title AS movie_title,
        ti.production_year AS movie_year,
        COUNT(DISTINCT c.id) AS co_stars_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        title ti ON c.movie_id = ti.id
    GROUP BY 
        ak.name, ak.person_id, ti.title, ti.production_year
),
ActorCoStarStats AS (
    SELECT 
        actor_name,
        movie_title,
        movie_year,
        AVG(co_stars_count) AS avg_co_stars,
        COUNT(*) AS movie_count
    FROM 
        ActorMovies
    GROUP BY 
        actor_name, movie_title, movie_year
),
TopActors AS (
    SELECT 
        actor_name,
        AVG(avg_co_stars) AS avg_co_stars_over_all_movies
    FROM 
        ActorCoStarStats
    GROUP BY 
        actor_name
    ORDER BY 
        avg_co_stars_over_all_movies DESC
    LIMIT 10
)

SELECT 
    ta.actor_name,
    ta.avg_co_stars_over_all_movies,
    COUNT(DISTINCT tm.movie_title) AS total_movies,
    STRING_AGG(DISTINCT tm.movie_title, ', ') AS movie_titles
FROM 
    TopActors ta
JOIN 
    ActorCoStarStats tm ON ta.actor_name = tm.actor_name
GROUP BY 
    ta.actor_name, ta.avg_co_stars_over_all_movies
ORDER BY 
    total_movies DESC;
