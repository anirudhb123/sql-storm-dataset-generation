WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cc.kind, ', ') AS company_types
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        keyword k ON t.id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type cc ON mc.company_type_id = cc.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
final_benchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keywords,
        COALESCE(md.company_types, 'No Companies') AS company_types,
        LENGTH(md.cast_names) AS cast_name_length,
        LENGTH(md.keywords) AS keyword_length
    FROM 
        movie_details md
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_names,
    keywords,
    company_types,
    cast_name_length,
    keyword_length,
    CASE 
        WHEN cast_name_length > 100 THEN 'Long Cast'
        ELSE 'Short Cast'
    END AS cast_size_category,
    CASE 
        WHEN keyword_length > 50 THEN 'Rich in Keywords'
        ELSE 'Keyword Sparse'
    END AS keyword_density
FROM 
    final_benchmark
ORDER BY 
    production_year DESC, title;
