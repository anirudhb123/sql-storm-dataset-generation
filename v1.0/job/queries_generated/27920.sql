WITH actor_movie_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.role_id,
        r.role AS character_name,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        a.id, a.name, t.title, t.production_year, c.role_id, r.role
), 
filtered_actor_movie_info AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year,
        character_name,
        keywords
    FROM 
        actor_movie_info
    WHERE 
        production_year BETWEEN 2000 AND 2023
)

SELECT 
    actor_name,
    COUNT(movie_title) AS total_movies,
    STRING_AGG(DISTINCT movie_title ORDER BY movie_title) AS movie_titles,
    STRING_AGG(DISTINCT keywords ORDER BY keywords) AS all_keywords
FROM 
    filtered_actor_movie_info
GROUP BY 
    actor_name
HAVING 
    COUNT(movie_title) > 5
ORDER BY 
    total_movies DESC;
