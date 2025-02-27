WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        co.name AS company_name,
        c.role AS cast_role,
        p.name AS person_name
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        role_type c ON ci.role_id = c.id
    WHERE 
        m.production_year >= 2000
),
ranked_movies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        company_name,
        cast_role,
        person_name,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS rn
    FROM 
        movie_data
)

SELECT 
    production_year,
    STRING_AGG(movie_title, ', ') AS titles,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT person_name || ' as ' || cast_role, '; ') AS cast
FROM 
    ranked_movies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
