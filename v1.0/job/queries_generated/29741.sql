WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        p.info AS actor_info
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        c.nr_order IS NOT NULL
),
top_movies AS (
    SELECT 
        movie_id,
        COUNT(actor_name) AS actor_count
    FROM 
        movie_actors
    GROUP BY 
        movie_id
    ORDER BY 
        actor_count DESC
    LIMIT 10
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    t.title,
    t.production_year,
    m.actor_count,
    STRING_AGG(k.keyword, ', ') AS keywords,
    STRING_AGG(ma.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT p.info, '; ') AS actor_info_details
FROM 
    top_movies m
JOIN 
    title t ON m.movie_id = t.id
JOIN 
    movie_actors ma ON t.id = ma.movie_id
LEFT JOIN 
    movie_keywords k ON t.id = k.movie_id
LEFT JOIN 
    aka_name a ON ma.actor_name = a.name
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
GROUP BY 
    t.title,
    t.production_year,
    m.actor_count
ORDER BY 
    m.actor_count DESC;
