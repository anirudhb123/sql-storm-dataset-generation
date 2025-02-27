WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = mc.company_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 AND 
        c.kind ILIKE '%production%'
    GROUP BY 
        t.title, t.production_year, c.kind
), 
detailed_movie_data AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_type,
        md.aka_names,
        md.keywords,
        md.cast_count,
        ARRAY_AGG(DISTINCT pi.info) AS person_info
    FROM 
        movie_data md
    LEFT JOIN 
        complete_cast cc ON md.movie_title = (SELECT t.title FROM aka_title t WHERE t.movie_id = cc.movie_id LIMIT 1)
    LEFT JOIN 
        person_info pi ON cc.person_id = pi.person_id
    GROUP BY 
        md.movie_title, md.production_year, md.company_type, md.aka_names, md.keywords, md.cast_count
)
SELECT 
    *,
    CASE
        WHEN cast_count > 5 THEN 'Large Cast'
        WHEN cast_count BETWEEN 3 AND 5 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    detailed_movie_data
ORDER BY 
    production_year DESC, movie_title;
