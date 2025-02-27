
WITH movie_overview AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT c.name, ',') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT co.name, ',') AS production_companies
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
formatted_overview AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        TRIM(BOTH ',' FROM cast_names) AS cast_names,
        TRIM(BOTH ',' FROM keywords) AS keywords,
        TRIM(BOTH ',' FROM production_companies) AS production_companies,
        CONCAT('Movie: ', movie_title, ' | Year: ', production_year, 
               ' | Cast: ', cast_names, 
               ' | Keywords: ', keywords, 
               ' | Companies: ', production_companies) AS full_overview
    FROM 
        movie_overview
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_names,
    keywords,
    production_companies,
    full_overview
FROM 
    formatted_overview
ORDER BY 
    production_year DESC, movie_title;
