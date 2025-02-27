
WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND a.name IS NOT NULL
    GROUP BY 
        t.title, t.production_year, a.name, c.kind
),
ranked_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_name, 
        cast_type,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_name) AS rank
    FROM 
        movie_data
)
SELECT 
    production_year,
    COUNT(*) AS total_movies,
    STRING_AGG(movie_title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT keywords, '; ') AS all_keywords
FROM 
    ranked_movies
GROUP BY 
    production_year
HAVING 
    COUNT(*) > 5
ORDER BY 
    production_year DESC;
