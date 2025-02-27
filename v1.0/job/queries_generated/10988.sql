-- Performance Benchmarking SQL Query
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        g.kind AS genre,
        ak.name AS actor_name,
        r.role AS actor_role
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        kind_type g ON t.kind_id = g.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    title_id,
    title,
    production_year,
    company_name,
    genre,
    actor_name,
    actor_role
FROM 
    movie_details
ORDER BY 
    production_year DESC, title;
