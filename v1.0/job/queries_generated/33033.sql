WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COALESCE(t.production_year, 'Unknown') AS movie_year,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(mh.depth) AS average_depth,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title t ON c.movie_id = t.id
WHERE 
    a.name IS NOT NULL
    AND a.name <> ''
    AND t.production_year IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.production_year
HAVING 
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY 
    movie_count DESC, actor_name
LIMIT 10;
