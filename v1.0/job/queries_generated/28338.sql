WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name, t.title, t.production_year
), actor_movie_counts AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        movie_actors
    GROUP BY 
        actor_name
), top_actors AS (
    SELECT 
        actor_name,
        movie_count
    FROM 
        actor_movie_counts
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    ma.movie_title,
    ma.production_year,
    ma.roles
FROM 
    top_actors ta
JOIN 
    movie_actors ma ON ta.actor_name = ma.actor_name
ORDER BY 
    ta.movie_count DESC, ma.production_year DESC;
