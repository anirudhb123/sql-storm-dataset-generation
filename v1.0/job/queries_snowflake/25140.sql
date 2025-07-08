WITH movie_credits AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        COUNT(DISTINCT mc.company_id) AS production_companies_count
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    JOIN 
        title AS t ON ci.movie_id = t.id
    JOIN 
        complete_cast AS cc ON cc.movie_id = t.id
    JOIN 
        movie_companies AS mc ON mc.movie_id = t.id
    JOIN 
        role_type AS r ON ci.role_id = r.id
    GROUP BY 
        a.name, t.title, t.production_year, r.role
),
top_movies AS (
    SELECT 
        movie_title, 
        production_year,
        actor_role,
        production_companies_count,
        ROW_NUMBER() OVER (PARTITION BY actor_role ORDER BY production_companies_count DESC) AS rank
    FROM 
        movie_credits
)
SELECT 
    actor_role,
    movie_title,
    production_year,
    production_companies_count
FROM 
    top_movies
WHERE 
    rank <= 5
ORDER BY 
    actor_role, production_companies_count DESC;
