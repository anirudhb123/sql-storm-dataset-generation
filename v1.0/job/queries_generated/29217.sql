WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id = (SELECT person_id FROM cast_info WHERE movie_id = t.movie_id LIMIT 1)
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    LEFT JOIN 
        role_type r ON r.id = ci.role_id
    GROUP BY 
        t.id, t.title, t.production_year
),
info_summary AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT info_type_id) AS info_count,
        STRING_AGG(info, ', ') AS info_text
    FROM 
        movie_info
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.company_names,
    md.keywords,
    md.roles,
    is.info_count,
    is.info_text
FROM 
    movie_details md
LEFT JOIN 
    info_summary is ON md.movie_id = is.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;
