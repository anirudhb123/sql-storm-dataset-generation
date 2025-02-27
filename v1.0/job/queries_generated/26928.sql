WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name), 'No companies') AS company_names,
        COALESCE(GROUP_CONCAT(DISTINCT ci.kind ORDER BY ci.kind), 'No cast types') AS cast_types
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
movie_info_stats AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keywords) AS total_keywords,
        COUNT(DISTINCT cast_names) AS total_cast,
        COUNT(DISTINCT company_names) AS total_companies
    FROM 
        movie_details
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    mis.total_keywords,
    mis.total_cast,
    mis.total_companies
FROM 
    movie_details md
JOIN 
    movie_info_stats mis ON md.movie_id = mis.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    total_keywords DESC, 
    total_cast DESC;
