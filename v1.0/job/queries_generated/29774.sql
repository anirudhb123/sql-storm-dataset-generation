WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT comp.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
    WHERE 
        t.production_year BETWEEN 1990 AND 2020
    GROUP BY 
        t.id
),
info_summary AS (
    SELECT 
        m.movie_id,
        COUNT(p.info) AS info_count, 
        STRING_AGG(DISTINCT p.info, ', ') AS captured_info
    FROM 
        movie_info m
    JOIN 
        movie_info_idx i ON m.id = i.movie_id
    JOIN 
        person_info p ON m.movie_id = p.person_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords,
    md.companies,
    is.info_count,
    is.captured_info
FROM 
    movie_details md
LEFT JOIN 
    info_summary is ON md.movie_id = is.movie_id
ORDER BY 
    md.production_year DESC, md.movie_id;
