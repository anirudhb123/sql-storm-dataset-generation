
WITH movie_details AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        c.kind AS company_type, 
        a.name AS actor_name,
        p.info AS person_info
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    title_id, 
    title, 
    production_year, 
    STRING_AGG(DISTINCT keyword, ', ') AS keywords, 
    STRING_AGG(DISTINCT company_type, ', ') AS companies, 
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT person_info, ', ') AS person_infos
FROM 
    movie_details
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, title ASC
LIMIT 100;
