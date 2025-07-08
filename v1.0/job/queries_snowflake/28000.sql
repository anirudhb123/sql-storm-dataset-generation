
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role,
        COUNT(DISTINCT ca.id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    JOIN 
        aka_name p ON ca.person_id = p.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, p.name, r.role
)
SELECT 
    title_id,
    title,
    production_year,
    LISTAGG(DISTINCT keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords,
    LISTAGG(DISTINCT company_name, ', ') WITHIN GROUP (ORDER BY company_name) AS companies,
    LISTAGG(DISTINCT person_name || ' (' || role || ')', ', ') WITHIN GROUP (ORDER BY person_name) AS cast_with_roles,
    MAX(cast_count) AS total_cast
FROM 
    movie_details
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, total_cast DESC
LIMIT 10;
