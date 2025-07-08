
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_info AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        ranked_movies m ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
outer_joins AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(a.actor_count, 0) AS actor_count,
        a.actors,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        m.total_movies
    FROM 
        ranked_movies m
    LEFT JOIN 
        actor_movie_info a ON m.movie_id = a.movie_id
    LEFT JOIN 
        movie_keywords mk ON m.movie_id = mk.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_count,
    actors,
    keywords,
    CASE 
        WHEN actor_count > 0 THEN 'Has Actors'
        ELSE 'No Actors'
    END AS actor_status,
    CASE 
        WHEN keywords = 'No keywords' THEN 'No keywords found'
        ELSE keywords
    END AS keyword_status
FROM 
    outer_joins
WHERE 
    total_movies >= 5
    AND (actor_count >= 2 OR keywords != 'No keywords')
ORDER BY 
    production_year DESC, title
LIMIT 50;
