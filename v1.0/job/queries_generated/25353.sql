WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS company_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
info_summary AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.aka_names,
        md.keywords,
        md.company_names,
        md.cast_count,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT id FROM title WHERE title = md.movie_title AND production_year = md.production_year LIMIT 1) 
    GROUP BY 
        md.movie_title, md.production_year, md.aka_names, md.keywords, md.company_names, md.cast_count
)
SELECT 
    movie_title,
    production_year,
    aka_names,
    keywords,
    company_names,
    cast_count,
    info_type_count
FROM 
    info_summary
WHERE 
    production_year >= 2000  -- Focusing on movies from the year 2000 and onward
ORDER BY 
    production_year DESC, 
    cast_count DESC
LIMIT 10;  -- Limiting to the top 10 results based on criteria
