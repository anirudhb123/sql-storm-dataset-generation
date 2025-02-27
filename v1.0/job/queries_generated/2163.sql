WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(mk.id), 0) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
actor_info AS (
    SELECT 
        ma.movie_id,
        ma.actor_name,
        md.title,
        md.production_year,
        md.keyword_count
    FROM 
        movie_actors ma
    JOIN 
        movie_details md ON ma.movie_id = md.movie_id
),
ranked_actors AS (
    SELECT 
        actor_name,
        title,
        production_year,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        actor_info
)
SELECT 
    actor_name,
    title,
    production_year,
    keyword_count,
    CASE 
        WHEN keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM 
    ranked_actors
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, rank
LIMIT 10;
