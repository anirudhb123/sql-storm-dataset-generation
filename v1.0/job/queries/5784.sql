WITH ranked_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
popular_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(ci.person_id) > 10
),
actor_movie_details AS (
    SELECT 
        ra.actor_id,
        ra.actor_name,
        pm.movie_id,
        pm.movie_title,
        pm.production_year
    FROM 
        ranked_actors ra
    JOIN 
        cast_info ci ON ra.actor_id = ci.person_id
    JOIN 
        popular_movies pm ON ci.movie_id = pm.movie_id
)
SELECT 
    amd.actor_id,
    amd.actor_name,
    COUNT(DISTINCT amd.movie_id) AS total_movies,
    STRING_AGG(DISTINCT amd.movie_title, ', ') AS movie_titles,
    AVG(pm.production_year) AS average_production_year
FROM 
    actor_movie_details amd
JOIN 
    popular_movies pm ON amd.movie_id = pm.movie_id
GROUP BY 
    amd.actor_id, amd.actor_name
ORDER BY 
    total_movies DESC
LIMIT 10;
