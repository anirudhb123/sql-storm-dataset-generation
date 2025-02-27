WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        title t
    JOIN 
        complete_cast c ON t.id = c.movie_id
    JOIN 
        cast_info ci ON c.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
    ORDER BY 
        t.production_year DESC
),
keyword_details AS (
    SELECT 
        m.movie_id,
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.role_name,
    STRING_AGG(DISTINCT kd.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT ci.company_name || ' (' || ci.company_type || ')', ', ') AS company_info
FROM 
    movie_details md
LEFT JOIN 
    keyword_details kd ON md.movie_title = kd.movie_id
LEFT JOIN 
    company_info ci ON md.movie_title = ci.movie_id
GROUP BY 
    md.movie_title, md.production_year, md.actor_name, md.role_name
ORDER BY 
    md.production_year DESC, md.movie_title;
