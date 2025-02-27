WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        a.name AS actor_name,
        p.info AS actor_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        person_info p ON a.person_id = p.person_id
)

SELECT 
    movie_id,
    title,
    production_year,
    company_name,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT actor_info, ', ') AS actor_infos
FROM 
    movie_details
GROUP BY 
    movie_id, title, production_year, company_name
ORDER BY 
    production_year DESC, movie_id;
