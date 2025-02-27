
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year
),
info_details AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info
    FROM 
        movie_info mi
    JOIN 
        aka_title m ON mi.movie_id = m.id
    GROUP BY 
        m.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    COALESCE(id.info, 'No additional info') AS additional_info
FROM 
    movie_details md
LEFT JOIN 
    info_details id ON md.movie_id = id.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 100;
