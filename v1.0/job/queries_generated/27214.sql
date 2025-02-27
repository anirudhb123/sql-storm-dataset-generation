WITH actor_movie_counts AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
), 
popular_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
), 
actor_movie_details AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        pm.movie_id,
        pm.movie_title,
        pm.production_year
    FROM 
        actor_movie_counts am
    JOIN 
        popular_movies pm ON am.movie_count > 3
)
SELECT 
    amd.actor_name,
    STRING_AGG(amd.movie_title, ', ') AS movies,
    COUNT(amd.movie_title) AS total_movies
FROM 
    actor_movie_details amd
GROUP BY 
    amd.actor_name
ORDER BY 
    total_movies DESC
LIMIT 10;

This SQL query performs several steps to benchmark string processing by analyzing actor participation in popular movies. It counts the number of movies associated with each actor, identifies popular movies based on the number of actors, and then retrieves the top actors with the most involvement in those popular films, displaying their names along with the titles of the movies they participated in. The output is limited to the top 10 actors.
