WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        string_agg(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.cast_count,
    COUNT(DISTINCT co.id) AS company_count,  
    STRING_AGG(DISTINCT co.name, ', ') AS companies
FROM 
    movie_details md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.aka_names, md.cast_count
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;