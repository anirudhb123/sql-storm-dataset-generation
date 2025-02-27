WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movies_with_actor_cnt AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        COUNT(cd.actor_name) AS actor_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_details cd ON rm.movie_id = cd.movie_id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year
),
keyword_data AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    COALESCE(m.actor_count, 0) AS total_actors,
    COALESCE(k.keywords, 'No keywords') AS movie_keywords
FROM 
    movies_with_actor_cnt m
LEFT JOIN 
    keyword_data k ON m.movie_id = k.movie_id
WHERE 
    (m.actor_count > 0 AND m.production_year >= 2000) OR 
    (m.actor_count = 0 AND m.production_year < 2000)
ORDER BY 
    m.production_year DESC, 
    m.movie_title ASC
LIMIT 50;
