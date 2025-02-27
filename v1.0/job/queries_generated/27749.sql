WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        c.country_code,
        a.name AS actor_name,
        r.role AS actor_role,
        pi.info AS actor_info
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        person_info pi ON pi.person_id = ci.person_id
    ) 

SELECT 
    movie_id,
    movie_title,
    production_year,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name || ' (' || country_code || ')', '; ') AS companies,
    STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ') AS cast,
    STRING_AGG(DISTINCT actor_info, '; ') AS actor_info
FROM 
    movie_details
GROUP BY 
    movie_id, movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
