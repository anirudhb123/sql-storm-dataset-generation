WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role
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
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year > 2000
)
SELECT 
    movie_id,
    title,
    production_year,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT person_name || ' (' || role || ')', ', ') AS cast
FROM 
    movie_details
GROUP BY 
    movie_id, title, production_year
ORDER BY 
    production_year DESC, title;
