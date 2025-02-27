
WITH movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        MAX(m.production_year) AS production_year
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.id, m.title
),
top_movies AS (
    SELECT 
        movie_id,
        movie_title,
        cast_names,
        production_year,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS ranking
    FROM 
        movie_cast
)
SELECT 
    production_year,
    STRING_AGG(movie_title || ' (Cast: ' || cast_names || ')', '; ') AS movies_and_cast
FROM 
    top_movies
WHERE 
    ranking <= 5
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
