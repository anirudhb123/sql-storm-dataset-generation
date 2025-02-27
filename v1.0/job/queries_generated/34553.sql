WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2020  -- Start with movies produced in 2020

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3  -- We want to limit the hierarchy to 3 levels deep
)

SELECT 
    p.name AS actor_name,
    COUNT(c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    AVG(m.production_year) AS avg_production_year,
    MAX(CASE WHEN m.production_year >= 2015 THEN 'Recent' ELSE 'Classic' END) AS movie_category,
    COALESCE(NULLIF(SUM(k.keyword IS NOT NULL), 0), 'No Keywords') AS keyword_status
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title m ON c.movie_id = m.id
GROUP BY 
    p.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 1  -- Only include actors with more than one movie
ORDER BY 
    total_movies DESC
LIMIT 10;   -- Limit to top 10 actors
