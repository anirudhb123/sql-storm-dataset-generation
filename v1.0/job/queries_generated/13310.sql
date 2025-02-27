WITH movie_cast AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        c.nr_order AS cast_order
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name a ON a.id = ci.person_id
)
SELECT 
    mc.movie_title,
    mc.actor_name,
    mc.cast_order
FROM 
    movie_cast mc
ORDER BY 
    mc.movie_title, 
    mc.cast_order;
