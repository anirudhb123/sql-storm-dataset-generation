WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        co.kind AS company_type,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT pn.info) AS person_infos
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type co ON mc.company_type_id = co.id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        person_info pn ON ci.person_id = pn.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year, c.name, co.kind
)
SELECT 
    movie_title,
    production_year,
    company_name,
    company_type,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT aka_names, ', ') AS alternate_names,
    STRING_AGG(DISTINCT person_infos, ', ') AS person_info
FROM 
    movie_data
ORDER BY 
    production_year DESC, movie_title;
