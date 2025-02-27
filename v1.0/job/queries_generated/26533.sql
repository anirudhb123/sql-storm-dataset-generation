WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        pc.role AS person_role,
        ak.name AS actor_name
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
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000 
        AND c.country_code = 'USA'
        AND k.keyword ILIKE '%action%'
        AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'biography')
)
SELECT 
    movie_title,
    production_year,
    string_agg(DISTINCT actor_name, ', ') AS actors,
    string_agg(DISTINCT company_name, ', ') AS companies,
    string_agg(DISTINCT movie_keyword, ', ') AS keywords,
    COUNT(DISTINCT person_role) AS roles_count
FROM 
    movie_details
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;

