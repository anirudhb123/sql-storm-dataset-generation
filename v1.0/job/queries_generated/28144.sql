WITH actor_movies AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
filtered_actors AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        movie_rank
    FROM 
        actor_movies
    WHERE 
        movie_rank <= 5
),
distinct_years AS (
    SELECT DISTINCT 
        production_year
    FROM 
        filtered_actors
),
actor_year_counts AS (
    SELECT 
        fa.actor_name,
        dy.production_year,
        COUNT(fa.movie_title) AS movie_count
    FROM 
        distinct_years dy
    JOIN 
        filtered_actors fa ON dy.production_year = fa.production_year
    GROUP BY 
        fa.actor_name, dy.production_year
)
SELECT 
    ay.actor_name,
    SUM(ay.movie_count) AS total_movies,
    AVG(ay.movie_count) AS avg_movies_per_year
FROM 
    actor_year_counts ay
GROUP BY 
    ay.actor_name
ORDER BY 
    total_movies DESC
LIMIT 10;

This query benchmarks string processing by identifying the top 10 actors based on the number of movies they starred in, restricted to their 5 most recent productions. It involves multiple Common Table Expressions (CTEs) to filter, count, and aggregate strings efficiently.
