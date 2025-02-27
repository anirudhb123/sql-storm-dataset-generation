WITH movie_actors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(ma.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_actors ma ON m.id = ma.movie_id
    LEFT JOIN 
        movie_keywords mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_count,
    md.keywords
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;