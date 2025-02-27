
WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        n.name AS actor_name,
        r.role AS actor_role,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        name n ON ci.person_id = n.imdb_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        title t ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
)
SELECT 
    movie_title,
    actor_name,
    actor_role,
    production_year
FROM 
    ranked_movies
WHERE 
    year_rank <= 3
ORDER BY 
    production_year DESC, 
    movie_title;
