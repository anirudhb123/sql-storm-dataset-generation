WITH movie_actor_info AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        p.id AS person_id,
        p.name AS actor_name,
        c.nr_order,
        r.role AS role_name,
        m.production_year
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year >= 2000
),
actor_movie_count AS (
    SELECT 
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM 
        movie_actor_info
    GROUP BY 
        actor_name
),
top_actors AS (
    SELECT 
        actor_name
    FROM 
        actor_movie_count
    WHERE 
        movie_count > 10
)
SELECT 
    m.movie_id,
    m.movie_title,
    ARRAY_AGG(DISTINCT a.actor_name) AS main_actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    m.production_year
FROM 
    movie_actor_info m
JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    top_actors a ON m.actor_name = a.actor_name
GROUP BY 
    m.movie_id, m.movie_title, m.production_year
ORDER BY 
    m.production_year DESC,
    m.movie_title;
