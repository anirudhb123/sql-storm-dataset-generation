WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.id) AS cast_ids,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT ci.kind) AS company_types
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
        AND ci.nr_order < 5
    GROUP BY 
        t.id
),

formatted_results AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COALESCE(md.cast_ids, 'No Cast') AS cast_ids,
        COALESCE(md.keywords, 'No Keywords') AS keywords,
        COALESCE(md.company_types, 'No Companies') AS company_types
    FROM 
        movie_details md
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_ids,
    fm.keywords,
    fm.company_types
FROM 
    formatted_results fm
ORDER BY 
    fm.production_year DESC, fm.movie_id ASC
LIMIT 50;
