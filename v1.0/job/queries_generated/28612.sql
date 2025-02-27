WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        ct.kind AS company_type,
        a.name AS actor_name,
        r.role AS actor_role
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword LIKE '%action%'
        AND c.country_code = 'USA'
)
SELECT 
    md.movie_title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.company_name || ' (' || md.company_type || ')', ', ') AS companies
FROM 
    movie_details md
GROUP BY 
    md.movie_id, md.movie_title, md.production_year
ORDER BY 
    md.production_year DESC, md.movie_title;
