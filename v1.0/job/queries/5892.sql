
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        STRING_AGG(DISTINCT p.info, ', ') AS person_infos
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
final_output AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COALESCE(md.keywords, 'No keywords') AS keywords,
        COALESCE(md.company_types, 'No companies') AS company_types,
        COALESCE(md.person_infos, 'No information') AS person_infos
    FROM 
        movie_details md
    ORDER BY 
        md.production_year DESC,
        md.title
)
SELECT 
    *
FROM 
    final_output
LIMIT 100;
