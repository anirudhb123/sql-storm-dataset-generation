WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.id) AS total_roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name, t.title, t.production_year
    HAVING 
        COUNT(ci.id) > 1
),

highlighted_movies AS (
    SELECT 
        movie_title,
        production_year,
        ARRAY_AGG(actor_name ORDER BY actor_name) AS actors_list
    FROM 
        movie_actors
    GROUP BY 
        movie_title, production_year
    ORDER BY 
        production_year DESC
    LIMIT 10
)

SELECT 
    hm.movie_title,
    hm.production_year,
    STRING_AGG(hm.actors_list::text, ', ') AS actors
FROM 
    highlighted_movies hm
GROUP BY 
    hm.movie_title, hm.production_year
ORDER BY 
    hm.production_year DESC;