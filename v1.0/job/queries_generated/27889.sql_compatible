
WITH movie_actors AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT ca.role_id) AS role_count
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id, ak.name, ak.id
),
movie_titles AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        kt.kind AS movie_genre
    FROM 
        aka_title mt
    JOIN 
        kind_type kt ON mt.kind_id = kt.id
),
actor_stats AS (
    SELECT 
        ma.movie_id,
        mt.movie_title,
        mt.production_year,
        mt.movie_genre,
        ma.actor_name,
        ma.role_count
    FROM 
        movie_actors ma
    JOIN 
        movie_titles mt ON ma.movie_id = mt.movie_id
),
top_performers AS (
    SELECT 
        actor_name,
        SUM(role_count) AS total_roles
    FROM 
        actor_stats
    GROUP BY 
        actor_name
    ORDER BY 
        total_roles DESC
    LIMIT 10
)
SELECT 
    ap.actor_name,
    COUNT(DISTINCT ap.movie_id) AS movie_count,
    STRING_AGG(ap.movie_title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT ap.movie_genre, ', ') AS genres,
    STRING_AGG(DISTINCT CAST(ap.production_year AS VARCHAR), ', ') AS years
FROM 
    actor_stats ap
JOIN 
    top_performers tp ON ap.actor_name = tp.actor_name
GROUP BY 
    ap.actor_name
ORDER BY 
    movie_count DESC;
