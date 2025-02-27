WITH RECURSIVE movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS casting_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.person_role_id = r.id
),
aggregated_cast AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(mc.actor_name, ', ') AS cast_names,
        COUNT(mc.actor_name) AS cast_count,
        MAX(mc.casting_order) AS total_casting_order
    FROM 
        movie_cast mc
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
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
    t.id AS movie_id,
    t.title,
    t.production_year,
    ac.cast_names,
    ac.cast_count,
    mk.keywords
FROM 
    title t
LEFT JOIN 
    aggregated_cast ac ON t.id = ac.movie_id
LEFT JOIN 
    movie_keywords mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC,
    ac.cast_count DESC;
