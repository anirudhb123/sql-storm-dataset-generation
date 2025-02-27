WITH movie_cast AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        a.name AS actor_name,
        c.nr_order AS cast_order,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, a.name, c.nr_order
),
top_movies AS (
    SELECT 
        mc.movie_id,
        mc.movie_title,
        mc.actor_name,
        mc.cast_order,
        ROW_NUMBER() OVER (PARTITION BY mc.actor_name ORDER BY mc.cast_order) AS actor_role_number
    FROM 
        movie_cast mc
    WHERE 
        mc.cast_order IS NOT NULL
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.actor_name,
    tm.cast_order,
    tm.actor_role_number,
    COUNT(tm.actor_role_number) OVER (PARTITION BY tm.actor_name) AS total_roles,
    STRING_AGG(DISTINCT mc.keywords, '; ') AS associated_keywords
FROM 
    top_movies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_id, tm.movie_title, tm.actor_name, tm.cast_order, tm.actor_role_number
ORDER BY 
    total_roles DESC, tm.actor_name;
