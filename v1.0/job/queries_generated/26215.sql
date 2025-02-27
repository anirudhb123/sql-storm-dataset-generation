WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
        AND c.country_code = 'USA'
),
actor_count AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        movie_details
    GROUP BY 
        actor_name
),
top_actors AS (
    SELECT 
        actor_name,
        movie_count
    FROM 
        actor_count
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    md.movie_title, 
    md.production_year, 
    ta.actor_name, 
    ta.movie_count
FROM 
    movie_details md
JOIN 
    top_actors ta ON md.actor_name = ta.actor_name
ORDER BY 
    md.production_year DESC, ta.movie_count DESC;
