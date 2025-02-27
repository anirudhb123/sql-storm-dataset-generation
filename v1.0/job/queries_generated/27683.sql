WITH movie_actor_info AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role,
        comp.name AS company_name
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name comp ON mc.company_id = comp.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND a.name IS NOT NULL
),

aggregate_info AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        COUNT(DISTINCT production_year) AS unique_years,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies
    FROM 
        movie_actor_info
    GROUP BY 
        actor_name
)

SELECT 
    actor_name,
    total_movies,
    unique_years,
    production_companies
FROM 
    aggregate_info
ORDER BY 
    total_movies DESC
LIMIT 10;
