
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS cast_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        LISTAGG(DISTINCT CONCAT(cname.name, ' (', ct.kind, ')'), ', ') WITHIN GROUP (ORDER BY cname.name, ct.kind) AS production_companies
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cname ON mc.company_id = cname.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.id, m.title, m.production_year
)

SELECT 
    md.title,
    md.production_year,
    COALESCE(md.cast_names, 'No Cast') AS cast_names,
    COALESCE(md.keywords, 'No Keywords') AS keywords,
    COALESCE(md.production_companies, 'No Production Companies') AS production_companies
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.title
LIMIT 50;
