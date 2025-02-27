WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.id AS movie_id,
        a.name AS actor_name,
        c.kind AS role_type,
        m.name AS production_company,
        ki.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) as actor_order
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
        AND a.name IS NOT NULL
        AND m.name IS NOT NULL
)
SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name ORDER BY actor_order) AS actors,
    STRING_AGG(DISTINCT production_company ORDER BY production_company) AS companies,
    STRING_AGG(DISTINCT movie_keyword ORDER BY movie_keyword) AS keywords
FROM 
    movie_details
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
