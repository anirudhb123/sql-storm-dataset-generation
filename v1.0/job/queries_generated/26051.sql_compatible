
WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        STRING_AGG(k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND a.name IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
ranked_movies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        keywords,
        company_types,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_name) AS rank
    FROM 
        movie_data
)
SELECT 
    production_year,
    COUNT(*) AS movie_count,
    STRING_AGG(actor_name, ', ') AS actors,
    STRING_AGG(keywords, ', ') AS all_keywords,
    STRING_AGG(DISTINCT company_types, ', ') AS distinct_companies
FROM 
    ranked_movies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
