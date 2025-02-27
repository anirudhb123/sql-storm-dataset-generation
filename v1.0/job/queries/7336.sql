
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT c.name, ',') AS companies,
        STRING_AGG(DISTINCT a.name, ',') AS cast
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
), 
director_info AS (
    SELECT 
        p.person_id,
        p.id AS director_id,
        a.name AS director_name
    FROM 
        person_info p
    JOIN 
        aka_name a ON p.person_id = a.person_id
    JOIN 
        role_type r ON p.info_type_id = r.id
    WHERE 
        r.role = 'Director'
), 
final_output AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        STRING_AGG(DISTINCT di.director_name, ',') AS directors
    FROM 
        movie_details md
    LEFT JOIN 
        director_info di ON md.movie_id = di.director_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.keywords, md.companies
)
SELECT 
    * 
FROM 
    final_output
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, title ASC;
