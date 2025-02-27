WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        co.name AS company_name,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id, m.title, m.production_year, co.name, k.keyword
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.keyword,
    md.cast_count
FROM 
    movie_details md
WHERE 
    md.cast_count > 5
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
