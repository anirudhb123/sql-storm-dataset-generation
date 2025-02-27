
WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        a.name AS actor_name,
        c.kind AS role_name,
        COUNT(*) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year, t.kind_id, a.name, c.kind
)
SELECT 
    md.title,
    md.production_year,
    md.role_name,
    md.actor_name,
    md.actor_count,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT cf.name, ', ') AS company_names
FROM 
    movie_details md
JOIN 
    movie_companies mc ON md.kind_id = mc.movie_id
JOIN 
    company_name cf ON mc.company_id = cf.id
GROUP BY 
    md.title, md.production_year, md.role_name, md.actor_name, md.actor_count
HAVING 
    COUNT(DISTINCT cf.id) > 1
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
