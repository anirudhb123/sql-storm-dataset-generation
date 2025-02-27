WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name c ON c.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id
), 
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), 
info_summary AS (
    SELECT 
        mi.movie_id,
        GROUP_CONCAT(DISTINCT it.info) AS info_data
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.cast_names,
    cd.companies,
    cd.company_types,
    is.info_data
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    info_summary is ON md.movie_id = is.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC;
