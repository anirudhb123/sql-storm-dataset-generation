WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3  
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    MIN(m.production_year) AS first_movie_year,
    MAX(m.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT m.title, '; ') AS movie_titles,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5  
ORDER BY 
    total_movies DESC
LIMIT 10;