
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        r.role AS person_role,
        a.name AS actor_name,
        t.id AS movie_id
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
KeywordDetails AS (
    SELECT 
        m.movie_id,
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.person_role,
    md.actor_name,
    STRING_AGG(kd.keyword, ', ') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
GROUP BY 
    md.movie_title, md.production_year, md.company_name, md.person_role, md.actor_name, md.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
