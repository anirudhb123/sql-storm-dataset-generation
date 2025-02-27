WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Filter for movies
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(SUM(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END), 0) AS total_cast,
    AVG(mh.level) AS avg_link_depth,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year >= 2000  -- Filter for movies produced after 2000
GROUP BY 
    ak.name, at.title
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1  -- Only include actors with multiple linked movies
ORDER BY 
    avg_link_depth DESC, total_cast DESC;
