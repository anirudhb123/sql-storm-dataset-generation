WITH ranked_movies AS (
    SELECT 
        k.keyword,
        t.title AS movie_title,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY k.keyword ORDER BY t.production_year DESC) AS rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title t ON mk.movie_id = t.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id 
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
top_movies AS (
    SELECT 
        keyword,
        movie_title,
        actor_name
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    keyword,
    COUNT(DISTINCT movie_title) AS movie_count,
    ARRAY_AGG(DISTINCT actor_name) AS actors
FROM 
    top_movies
GROUP BY 
    keyword
ORDER BY 
    movie_count DESC;

This SQL query benchmarks string processing by analyzing movies from the year 2000 onward, linking keywords with their associated titles and actors, and aggregating the results to identify the most frequent keywords along with their corresponding movie counts and actor names.
