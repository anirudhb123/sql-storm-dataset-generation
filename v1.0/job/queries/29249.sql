WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        c.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND r.role LIKE 'Actor%'
)

SELECT 
    md.movie_title,
    md.production_year,
    COUNT(DISTINCT md.actor_name) AS actor_count,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.company_type, ', ') AS companies
FROM 
    movie_details md
GROUP BY 
    md.movie_title, md.production_year
ORDER BY 
    md.production_year DESC, actor_count DESC
LIMIT 100;
