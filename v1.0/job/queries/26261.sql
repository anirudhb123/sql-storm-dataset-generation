
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ka.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ka ON cc.subject_id = ka.person_id 
    GROUP BY 
        t.id, t.title, t.production_year
),
person_roles AS (
    SELECT 
        ci.person_id AS person_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) AS role_count,
        ci.movie_id AS movie_id
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id, a.name, r.role, ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.companies,
    pr.actor_name,
    pr.role_name,
    pr.role_count
FROM 
    movie_details md
LEFT JOIN 
    person_roles pr ON md.movie_id = pr.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, pr.role_count DESC
LIMIT 100;
