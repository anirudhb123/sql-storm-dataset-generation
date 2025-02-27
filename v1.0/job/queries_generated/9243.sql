WITH MovieDetails AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        c.kind AS company_kind
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    title_id, 
    title, 
    production_year, 
    STRING_AGG(actor_name, ', ') AS actors, 
    STRING_AGG(DISTINCT company_kind, ', ') AS companies
FROM 
    MovieDetails
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, title;
