
WITH movie_details AS (
    SELECT 
        mv.id AS movie_id,
        mv.title AS movie_title,
        mv.production_year,
        STRING_AGG(DISTINCT actor.name, ', ') AS cast,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        aka_title mv
    JOIN 
        cast_info ci ON mv.id = ci.movie_id
    JOIN 
        aka_name actor ON ci.person_id = actor.person_id
    LEFT JOIN 
        movie_keyword mk ON mv.id = mk.movie_id
    LEFT JOIN 
        keyword ON mk.keyword_id = keyword.id
    GROUP BY 
        mv.id, mv.title, mv.production_year
), 
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT cty.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cty ON mc.company_type_id = cty.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast,
    md.keywords,
    cd.companies,
    cd.company_types
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.movie_title ASC;
