WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        rp.role AS role_description,
        c.name AS company_name
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rp ON ci.role_id = rp.id
    WHERE 
        t.production_year > 2000
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
),
unique_movies AS (
    SELECT 
        movie_title, 
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_name, ', ') AS companies
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    companies
FROM 
    unique_movies
ORDER BY 
    production_year DESC, movie_title;
