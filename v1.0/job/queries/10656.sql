WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        r.role,
        a.name AS actor_name
    FROM 
        aka_title t
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
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.role,
    md.actor_name
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
