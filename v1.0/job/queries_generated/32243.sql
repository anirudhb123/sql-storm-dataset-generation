WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Starting from the year 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,  -- Get the linked movie ID
        mt.title,
        mt.production_year,
        h.depth + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id 
    JOIN 
        movie_hierarchy h ON ml.movie_id = h.movie_id
)
SELECT 
    h.movie_id, 
    h.title, 
    h.production_year, 
    h.depth,
    COALESCE(p.name, 'Unknown') AS director_name,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(mi.info_type_id) AS avg_info_type_id
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id 
LEFT JOIN 
    cast_info ci ON ci.movie_id = h.movie_id AND ci.nr_order = 1  -- Director's role assumed to be nr_order = 1
LEFT JOIN 
    aka_name p ON p.person_id = ci.person_id 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = h.movie_id
LEFT JOIN 
    keyword kc ON kc.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = h.movie_id
WHERE 
    h.depth <= 3  -- Limiting depth for performance checking
GROUP BY 
    h.movie_id, h.title, h.production_year, h.depth, p.name
HAVING 
    COUNT(DISTINCT kc.keyword) > 5  -- Only movies with more than 5 unique keywords
ORDER BY 
    h.production_year DESC, keyword_count DESC
LIMIT 10;  -- Retrieve a limited set of results for performance benchmarking
