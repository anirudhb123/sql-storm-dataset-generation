WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.depth + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy h ON e.episode_of_id = h.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COALESCE(c.kind, 'Unknown Role') AS role,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(CASE WHEN mi.info IS NOT NULL THEN mi.info ELSE '0' END::numeric) AS average_rating
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating' LIMIT 1)
GROUP BY 
    m.movie_id, a.name, c.kind
HAVING 
    COUNT(DISTINCT k.keyword) >= 3
ORDER BY 
    m.production_year DESC, average_rating DESC;
