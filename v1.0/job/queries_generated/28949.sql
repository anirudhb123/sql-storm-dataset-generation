WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        kind_type kt ON mc.company_type_id = kt.id
    JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_type,
    md.company_names,
    md.aka_names,
    md.keywords,
    md.cast_count,
    CASE 
        WHEN md.cast_count > 20 THEN 'Large Cast'
        WHEN md.cast_count BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    movie_data md
ORDER BY 
    md.production_year DESC, 
    md.title;

