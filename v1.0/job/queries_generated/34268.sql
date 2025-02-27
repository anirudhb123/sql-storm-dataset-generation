WITH RECURSIVE MovieConnections AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY[m.title] AS connection_path,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 -- Focus on movies from the year 2000 onwards

    UNION ALL

    SELECT 
        mc.linked_movie_id AS movie_id,
        t.title,
        connection_path || t.title,
        depth + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title t ON mc.linked_movie_id = t.id
    JOIN 
        MovieConnections c ON mc.movie_id = c.movie_id
    WHERE 
        depth < 3 -- Limit depth to avoid too deep recursion
)

SELECT 
    m.id AS movie_id,
    m.title,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT r.id) AS total_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(ci.note) AS cast_note,
    AVG(mi.production_year) AS avg_movie_year,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_order
FROM 
    aka_title m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    MovieConnections mc ON m.id = mc.movie_id
WHERE 
    (mi.info IS NULL OR mi.info NOT LIKE '%prohibited%') -- Filtering specific info types
    AND m.production_year >= 2000 -- Limiting to recent movies
GROUP BY 
    m.id, m.title, a.name
HAVING 
    COUNT(DISTINCT r.id) > 1 -- Ensuring at least two different roles per movie
ORDER BY 
    avg_movie_year DESC, total_roles DESC
LIMIT 50;
