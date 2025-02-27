
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        a.name AS actor_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, a.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    COALESCE(md.keywords, 'No Keywords') AS keywords,
    COALESCE(md.companies, 'No Companies') AS companies
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 50;
