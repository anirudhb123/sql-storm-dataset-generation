WITH movie_cast AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        r.role AS actor_role,
        t.production_year,
        COALESCE(k.keyword, 'N/A') AS keyword,
        c.kind AS company_type
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
)
SELECT 
    movie_title,
    COUNT(actor_name) AS total_actors, 
    ARRAY_AGG(DISTINCT actor_name) AS actor_list,
    ARRAY_AGG(DISTINCT keyword) AS keywords,
    ARRAY_AGG(DISTINCT company_type) AS companies
FROM 
    movie_cast
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, total_actors DESC
LIMIT 100;