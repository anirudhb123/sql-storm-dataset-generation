
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        rt.role AS actor_role,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year, a.name, rt.role
    ORDER BY 
        t.production_year DESC, a.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.actor_role,
    md.keywords,
    md.companies
FROM 
    MovieDetails md
WHERE 
    md.keywords LIKE '%drama%' 
    AND md.companies IS NOT NULL
FETCH FIRST 50 ROWS ONLY;
