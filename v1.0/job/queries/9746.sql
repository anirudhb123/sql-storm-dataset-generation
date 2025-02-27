WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        r.role AS actor_role
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND c.kind = 'Distributor'
)
SELECT 
    movie_title,
    production_year,
    COUNT(DISTINCT actor_name) AS number_of_actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM 
    movie_details
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, number_of_actors DESC
LIMIT 50;
