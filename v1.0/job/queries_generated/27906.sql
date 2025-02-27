WITH movie_cast AS (
    SELECT 
        t.title AS movie_title, 
        p.name AS actor_name,
        c.nr_order AS role_order,
        r.role AS actor_role,
        m.production_year,
        kt.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        t.production_year >= 2000
),
ranked_movies AS (
    SELECT 
        movie_title, 
        actor_name,
        actor_role,
        production_year,
        ROW_NUMBER() OVER (PARTITION BY movie_title ORDER BY role_order) AS actor_rank
    FROM 
        movie_cast
)

SELECT 
    movie_title,
    STRING_AGG(CONCAT(actor_rank, ': ', actor_name, ' (', actor_role, ')'), ', ') AS full_cast,
    production_year
FROM 
    ranked_movies
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
