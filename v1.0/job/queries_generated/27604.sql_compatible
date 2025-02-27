
WITH movie_data AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        company.name AS production_company,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name company ON mc.company_id = company.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = mt.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        aka_name ak ON mt.id = ak.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.title, mt.production_year, company.name
)
SELECT 
    movie_title,
    production_year,
    production_company,
    aka_names,
    keywords,
    cast_count
FROM 
    movie_data
WHERE 
    cast_count > 5
ORDER BY 
    production_year DESC,
    cast_count DESC;
