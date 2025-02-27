
WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ',') AS aka_names,
        STRING_AGG(DISTINCT c.name, ',') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN aka_name ak ON t.id = ak.person_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),

filtered_movies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.aka_names,
        md.company_names,
        md.keywords,
        md.cast_count
    FROM 
        movie_data md
    WHERE 
        md.cast_count > 10 
        AND md.production_year = 2020
)

SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.aka_names,
    f.company_names,
    f.keywords,
    f.cast_count
FROM 
    filtered_movies f
ORDER BY 
    f.cast_count DESC
LIMIT 10;
