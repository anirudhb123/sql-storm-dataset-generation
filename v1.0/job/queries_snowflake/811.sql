
WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
actors_info AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        c.movie_id, a.name
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    ai.actor_name,
    COALESCE(ai.num_actors, 0) AS actor_count,
    mk.keywords
FROM 
    ranked_movies r
LEFT JOIN 
    actors_info ai ON r.movie_id = ai.movie_id
LEFT JOIN 
    movie_keywords mk ON r.movie_id = mk.movie_id
WHERE 
    r.production_year BETWEEN 2000 AND 2023
    AND (ai.num_actors > 2 OR ai.num_actors IS NULL)
ORDER BY 
    r.production_year DESC, r.title_rank
LIMIT 100;
