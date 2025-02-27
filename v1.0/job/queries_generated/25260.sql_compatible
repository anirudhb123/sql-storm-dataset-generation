
WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
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
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id, m.title, m.production_year
),
info_summary AS (
    SELECT
        md.movie_id,
        COALESCE(mi.info, 'No Info') AS movie_info,
        COUNT(pi.info) AS personal_info_count
    FROM 
        movie_data md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    LEFT JOIN 
        person_info pi ON md.movie_id = pi.person_id
    GROUP BY 
        md.movie_id, mi.info
),
final_results AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.actors,
        md.keywords,
        md.companies,
        ist.movie_info,
        ist.personal_info_count
    FROM 
        movie_data md
    JOIN 
        info_summary ist ON md.movie_id = ist.movie_id
)
SELECT 
    movie_title,
    production_year,
    actors,
    keywords,
    companies,
    movie_info,
    personal_info_count
FROM 
    final_results
ORDER BY 
    production_year DESC;
