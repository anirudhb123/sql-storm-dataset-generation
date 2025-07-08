
WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS role,
        m.name AS production_company,
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
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
        AND a.name IS NOT NULL
)
SELECT 
    movie_title,
    production_year,
    LISTAGG(DISTINCT actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actors,
    LISTAGG(DISTINCT role, ', ') WITHIN GROUP (ORDER BY role) AS roles,
    LISTAGG(DISTINCT production_company, ', ') WITHIN GROUP (ORDER BY production_company) AS production_companies,
    LISTAGG(DISTINCT movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords
FROM 
    movie_data
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
