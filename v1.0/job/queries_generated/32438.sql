WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1,
        CAST(h.path || ' > ' || m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy h ON m.episode_of_id = h.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    COUNT(DISTINCT mi.info) AS unique_movie_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    h.path AS movie_path,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info IS NOT NULL
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_hierarchy h ON t.id = h.movie_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.role_id, h.path
HAVING 
    COUNT(DISTINCT mi.info) > 1
ORDER BY 
    actor_name, movie_title;
