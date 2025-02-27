WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COALESCE(MAX(t.production_year), 0) AS max_production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC, MAX(t.production_year) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
top_ranked_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.cast_count,
        rm.max_production_year,
        rm.keywords
    FROM 
        ranked_movies rm
    WHERE
        rm.rank <= 10
),
actor_details AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.max_production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        top_ranked_movies t ON ci.movie_id = t.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.cast_count,
    rm.max_production_year,
    rm.keywords,
    ad.actor_name
FROM 
    top_ranked_movies rm
LEFT JOIN 
    actor_details ad ON rm.movie_id = ad.movie_id
ORDER BY 
    rm.cast_count DESC, rm.max_production_year DESC, rm.title;

This SQL query benchmarks string processing by summarizing string aggregate functions, counting distinct actors in titles, and joining necessary tables to provide a holistic overview of the top 10 movies with the most prominent casts, alongside the actors involved. The use of Common Table Expressions (CTEs) enhances clarity and allows for modular development of the query logic.
