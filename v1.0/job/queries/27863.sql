WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        r.role AS person_role,
        a.name AS actor_name
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),

keyword_summary AS (
    SELECT 
        md.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_details md ON mk.movie_id = md.movie_id
    GROUP BY 
        md.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.person_role,
    md.actor_name,
    ks.keywords
FROM 
    movie_details md
LEFT JOIN 
    keyword_summary ks ON md.movie_id = ks.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
