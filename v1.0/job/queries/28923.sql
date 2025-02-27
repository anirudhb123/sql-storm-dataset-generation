WITH movie_actor_info AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        a.name AS actor_name,
        c.nr_order AS role_order,
        r.role AS actor_role
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year >= 2000
        AND r.role IN ('Lead', 'Supporting')
),
keyword_count AS (
    SELECT 
        mc.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_companies mc ON mk.movie_id = mc.movie_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.actor_name,
    m.role_order,
    m.actor_role,
    k.keyword_count
FROM 
    movie_actor_info m
LEFT JOIN 
    keyword_count k ON m.movie_id = k.movie_id
ORDER BY 
    m.movie_title ASC, 
    m.role_order ASC;
