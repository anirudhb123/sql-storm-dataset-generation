WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL  -- Get top-level movies
    
    UNION ALL
    
    SELECT 
        e.movie_id,
        mt.title,
        mt.production_year,
        h.level + 1
    FROM 
        movie_hierarchy AS h
    JOIN 
        aka_title AS mt ON h.movie_id = mt.episode_of_id
    WHERE 
        h.level < 5  -- Limit recursion depth to avoid infinite loop
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COALESCE(ci.note, 'No role specified') AS role,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY m.id) AS actors_with_role_count,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_hierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    m.production_year > 2000  -- Filter for movies produced after the year 2000
    AND (ci.note ILIKE '%lead%' OR ci.note ILIKE '%starring%')  -- Filter for lead roles
GROUP BY 
    a.name, m.id, m.title, m.production_year, ci.note
HAVING 
    COUNT(DISTINCT kc.id) > 5  -- Only include movies with more than 5 unique keywords
ORDER BY 
    m.production_year DESC, actor_rank;
