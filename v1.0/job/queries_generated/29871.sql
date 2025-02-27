WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ac.name ORDER BY ac.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies,
        COUNT(DISTINCT ci.individual_role_id) AS cast_count
    FROM
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ac ON ci.person_id = ac.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id
),
movie_info_summary AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actors,
        md.keywords,
        md.companies,
        md.cast_count,
        COALESCE(AVG(mo.info_type_id), 0) AS average_info_type,
        COUNT(DISTINCT mo.info) AS unique_info_count
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mo ON md.movie_id = mo.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.actors, md.keywords, md.companies, md.cast_count
)
SELECT 
    movie_id,
    title,
    production_year,
    actors,
    keywords,
    companies,
    cast_count,
    average_info_type,
    unique_info_count
FROM 
    movie_info_summary
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, unique_info_count DESC
LIMIT 100;
