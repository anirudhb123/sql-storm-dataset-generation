
WITH movie_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        pt.name AS person_name,
        r.role AS person_role
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name pt ON ci.person_id = pt.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    title_id,
    title,
    production_year,
    LISTAGG(DISTINCT movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords,
    LISTAGG(DISTINCT company_name, ', ') WITHIN GROUP (ORDER BY company_name) AS companies,
    LISTAGG(DISTINCT person_name || ' (' || person_role || ')', ', ') WITHIN GROUP (ORDER BY person_name) AS cast_and_roles
FROM 
    movie_titles
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, title;
