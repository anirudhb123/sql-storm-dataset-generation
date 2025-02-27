
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        c.kind AS company_type
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, c.kind
),
final_benchmark AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actors,
        keywords,
        company_type
    FROM 
        movie_details
    WHERE 
        actors IS NOT NULL AND CHAR_LENGTH(actors) > 3
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.actors,
    f.keywords,
    f.company_type,
    CHAR_LENGTH(f.movie_title) AS title_length,
    CHAR_LENGTH(f.actors) AS actors_length,
    CHAR_LENGTH(f.keywords) AS keywords_length
FROM 
    final_benchmark f
ORDER BY 
    f.production_year DESC, 
    title_length DESC
LIMIT 100;
