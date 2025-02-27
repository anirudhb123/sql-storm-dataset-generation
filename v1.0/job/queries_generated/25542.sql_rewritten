WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
), 
actor_movie_casts AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        a.id AS actor_id
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year AS year,
        COUNT(DISTINCT ac.actor_id) AS num_actors,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        actor_movie_casts ac ON t.id = ac.movie_id
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.year,
    md.num_actors,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.year >= 2000 AND md.num_actors > 5
ORDER BY 
    md.num_actors DESC, 
    md.movie_title ASC;