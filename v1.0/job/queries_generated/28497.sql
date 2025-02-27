WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
actor_movie_info AS (
    SELECT 
        p.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ct.kind AS role_type
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        role_type ct ON ci.role_id = ct.id
    WHERE 
        p.name IS NOT NULL
)
SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    a.actor_name,
    a.role_type,
    r.movie_keyword,
    r.rank_per_year
FROM 
    ranked_movies r
JOIN 
    actor_movie_info a ON r.movie_title = a.movie_title AND r.production_year = a.production_year
WHERE 
    r.rank_per_year <= 5
ORDER BY 
    r.production_year DESC, 
    r.rank_per_year, 
    a.actor_name;

This SQL query is designed to benchmark string processing by delivering a comprehensive view of recent movies (from 2000 to 2023), their titles, and cast members. It uses Common Table Expressions (CTEs) to organize data, ranking the top 5 movies per production year based on the keyword associations and including role types for actors involved. The final output lists eligible movies sorted by their production year and ranks, providing insight into both movie titles and actors.
