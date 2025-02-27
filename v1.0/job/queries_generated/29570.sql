WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT mc.company_id) AS companies_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
info_data AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT pi.info, '; ') AS person_info,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_info
    FROM 
        movie_data m
    LEFT JOIN 
        person_info pi ON m.movie_id = pi.person_id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.companies_count,
    md.keywords,
    id.person_info,
    id.movie_info
FROM 
    movie_data md
LEFT JOIN 
    info_data id ON md.movie_id = id.movie_id
ORDER BY 
    md.production_year DESC, md.title;

