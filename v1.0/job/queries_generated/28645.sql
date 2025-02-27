WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        GROUP_CONCAT(DISTINCT a.name) AS actors
    FROM 
        aka_title m 
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
info_summary AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT person_id) AS total_cast,
        COUNT(DISTINCT company_id) AS total_companies
    FROM 
        movie_companies 
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.keywords,
    md.companies,
    md.actors,
    is.total_cast,
    is.total_companies
FROM 
    movie_details md
JOIN 
    info_summary is ON md.movie_id = is.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
