WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS cast_names,
        GROUP_CONCAT(DISTINCT comp.name ORDER BY comp.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        m.id
),
keywords_count AS (
    SELECT 
        movie_id, 
        COUNT(DISTINCT keyword) AS keyword_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
),
final_results AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.companies,
        md.keywords,
        kc.keyword_count
    FROM 
        movie_details md
    LEFT JOIN 
        keywords_count kc ON md.movie_id = kc.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_names,
    f.companies,
    f.keywords,
    COALESCE(f.keyword_count, 0) AS keyword_count
FROM 
    final_results f
ORDER BY 
    f.production_year DESC, 
    f.title ASC;

