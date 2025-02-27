
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ' ORDER BY a.name) AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ' ORDER BY k.keyword) AS keywords,
        COALESCE(STRING_AGG(DISTINCT c.name, ', ' ORDER BY c.name), 'No company') AS production_companies
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
info_summary AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.actors,
        md.keywords,
        md.production_companies,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON mi.movie_id = md.movie_id
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year, md.actors, md.keywords, md.production_companies
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actors,
    keywords,
    production_companies,
    info_count
FROM 
    info_summary
WHERE 
    info_count > 1
ORDER BY 
    production_year DESC, actors;
