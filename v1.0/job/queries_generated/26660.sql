WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        c.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.id = cc.subject_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type c ON c.id = mc.company_type_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
)
SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ') AS actors,
    STRING_AGG(DISTINCT company_type, ', ') AS production_companies,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM 
    movie_data
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
