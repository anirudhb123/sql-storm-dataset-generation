WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Assume '1' corresponds to a certain type of movie, e.g., 'feature film'
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit the hierarchy depth
)
SELECT 
    a.person_id,
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    SUM(m.production_year) AS total_production_years,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
WHERE 
    t.production_year IS NOT NULL 
    AND a.name IS NOT NULL
GROUP BY 
    a.person_id, a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 10  -- Only include actors with more than 10 movies
ORDER BY 
    total_production_years DESC, movies_count ASC;

-- Optionally also check for actors with no movies
SELECT 
    DISTINCT a.name AS actor_name 
FROM 
    aka_name a
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM cast_info c 
        WHERE c.person_id = a.person_id
    ) 
    AND a.name IS NOT NULL;
