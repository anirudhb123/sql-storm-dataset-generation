WITH movie_actor_count AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
),
top_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        actor_count DESC
    LIMIT 10
),
detailed_movie_info AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        ac.movie_count AS actor_count,
        string_agg(DISTINCT a.actor_name, ', ') AS actors,
        string_agg(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        top_movies m
    LEFT JOIN 
        movie_actor_count ac ON m.movie_id = ac.movie_id
    LEFT JOIN 
        movie_keyword mw ON m.movie_id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        m.movie_id, m.movie_title, m.production_year, ac.movie_count
)
SELECT 
    movie_title,
    production_year,
    actor_count,
    actors,
    keywords
FROM 
    detailed_movie_info
ORDER BY 
    production_year DESC, actor_count DESC;


