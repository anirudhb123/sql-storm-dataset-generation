
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT c.kind, ', ') WITHIN GROUP (ORDER BY c.kind) AS company_types,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.actors,
    md.company_types,
    md.keywords,
    COUNT(DISTINCT ci.person_id) AS total_cast_members
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
GROUP BY 
    md.movie_id, md.movie_title, md.production_year, md.actors, md.company_types, md.keywords
ORDER BY 
    md.production_year DESC, md.movie_title ASC;
