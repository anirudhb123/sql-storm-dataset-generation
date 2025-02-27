WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year
    FROM 
        ranked_movies
    WHERE 
        rn <= 5
),
actor_info AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
)
SELECT 
    tm.title AS top_movie,
    tm.production_year,
    ai.actor_name,
    ai.movie_count,
    ai.movies
FROM 
    top_movies tm
LEFT JOIN 
    actor_info ai ON tm.title = ANY(STRING_TO_ARRAY(ai.movies, ', '))
ORDER BY 
    tm.production_year DESC, 
    ai.movie_count DESC;
