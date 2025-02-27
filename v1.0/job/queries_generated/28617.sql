WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        ARRAY_AGG(DISTINCT c.name) AS companies
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year >= 2000 
        AND m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        m.id, m.title, m.production_year
),
info_data AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(DISTINCT CONCAT(i.info_type_id, ': ', i.info)) AS info_details
    FROM 
        movie_info i
    JOIN 
        movie_data m ON m.movie_id = i.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.actors,
    md.companies,
    COALESCE(id.info_details, '{}') AS additional_info
FROM 
    movie_data md
LEFT JOIN 
    info_data id ON md.movie_id = id.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;
