
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000 
        AND t.production_year <= 2023
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT co.id) > 0
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.company_names,
    md.cast_count,
    md.keywords
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 50;
