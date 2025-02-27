WITH RECURSIVE actor_hierarchy AS (
    -- Base case: Start with all actors and their roles
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id

    UNION ALL
    
    -- Recursive case: Find all movies related to actors
    SELECT 
        ch.cast_id,
        m.movie_id,
        ah.actor_name,
        r.role AS role_name,
        depth + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ch ON ah.movie_id = ch.movie_id
    JOIN 
        role_type r ON ch.role_id = r.id
    JOIN 
        aka_title m ON ch.movie_id = m.id
    WHERE 
        ah.cast_id <> ch.id -- Prevent processing the same actor in the recursion to avoid infinite loops
)
SELECT 
    a.actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ch.cast_id) OVER (PARTITION BY a.actor_name) AS co_actor_count,
    STRING_AGG(DISTINCT r.role, ', ') OVER (PARTITION BY a.actor_name) AS roles_played
FROM 
    actor_hierarchy a
JOIN 
    aka_title m ON a.movie_id = m.id
JOIN 
    cast_info ch ON a.movie_id = ch.movie_id
JOIN 
    role_type r ON ch.role_id = r.id
WHERE 
    m.production_year >= 2000 
    AND a.actor_name IS NOT NULL 
    AND (m.note IS NULL OR m.note <> 'N/A')
ORDER BY 
    a.actor_name, a.movie_id;

-- Additional example to demonstrate outer join and aggregation
SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    COALESCE(AVG(m.production_year), 0) AS avg_production_year,
    MAX(COALESCE(m.production_year, 0)) AS last_movie_year
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    aka_title m ON c.movie_id = m.id
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    avg_production_year DESC;
