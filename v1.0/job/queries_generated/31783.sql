WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        NULL::INTEGER AS parent_movie_id,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(COALESCE(py.production_year, 0)) AS average_production_year,
    STRING_AGG(DISTINCT m.movie_title, ', ') AS movies_list
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    (SELECT movie_id, MAX(production_year) AS production_year
     FROM aka_title
     GROUP BY movie_id) py ON c.movie_id = py.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC;
