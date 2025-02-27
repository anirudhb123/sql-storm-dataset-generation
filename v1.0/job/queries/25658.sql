WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ARRAY_AGG(DISTINCT p.name) AS cast,
        COALESCE(COUNT(DISTINCT ci.role_id), 0) AS role_count,
        AVG(mt.info_length) AS avg_info_length
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN (
        SELECT 
            movie_id,
            LENGTH(info) AS info_length
        FROM 
            movie_info
    ) mt ON m.id = mt.movie_id
    WHERE 
        m.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    md.cast,
    md.role_count,
    md.avg_info_length
FROM 
    movie_details md
WHERE 
    md.role_count > 0
ORDER BY 
    md.production_year DESC, md.role_count DESC;
