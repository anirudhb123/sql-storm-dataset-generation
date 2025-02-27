
WITH movie_actor_counts AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),

movie_info_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT m_keyword.keyword_id) AS total_keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword m_keyword ON m.id = m_keyword.movie_id
    LEFT JOIN 
        keyword kw ON m_keyword.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),

actor_movie_keywords AS (
    SELECT 
        mac.actor_id,
        mac.actor_name,
        mid.movie_id,
        mid.movie_title,
        mid.production_year,
        mid.keywords,
        mid.total_keywords
    FROM 
        movie_actor_counts mac
    JOIN 
        cast_info ci ON mac.actor_id = ci.person_id
    JOIN 
        movie_info_data mid ON ci.movie_id = mid.movie_id
)

SELECT 
    amk.actor_id,
    amk.actor_name,
    amk.movie_title,
    amk.production_year,
    amk.keywords,
    amk.total_keywords
FROM 
    actor_movie_keywords amk
WHERE 
    amk.total_keywords > 3
ORDER BY 
    amk.production_year DESC,
    amk.total_keywords DESC
LIMIT 10;
