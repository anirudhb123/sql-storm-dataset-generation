WITH movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COALESCE(comp.name, 'Independent') AS company_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name comp ON comp.id = mc.company_id
    WHERE 
        m.production_year IS NOT NULL AND m.production_year > 2000
),
final_result AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        mc.total_cast,
        mc.cast_names
    FROM 
        movie_details md
    LEFT JOIN 
        movie_cast mc ON mc.movie_id = md.movie_id
    WHERE 
        md.rn = 1
)

SELECT 
    *,
    CASE 
        WHEN total_cast IS NULL THEN 'No Cast Available'
        ELSE total_cast 
    END AS cast_status,
    CONCAT(title, ' (', production_year, ') - ', keyword) AS detailed_info
FROM 
    final_result
ORDER BY 
    production_year DESC, title;
