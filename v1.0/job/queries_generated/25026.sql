WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id
),
info_summary AS (
    SELECT 
        m.title_id,
        COUNT(DISTINCT mi.info) AS info_count,
        STRING_AGG(DISTINCT it.info) AS info_types
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    inf.info_count,
    inf.info_types
FROM 
    movie_details md
LEFT JOIN 
    info_summary inf ON md.title_id = inf.title_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC;
