WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        com.name AS company_name,
        ct.kind AS company_type,
        ct.id AS company_type_id
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name com ON mc.company_id = com.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        m.production_year >= 2000
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT CONCAT(md.company_name, ' (', md.company_type, ')'), '; ') AS companies
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year
ORDER BY 
    md.production_year DESC, md.title;
