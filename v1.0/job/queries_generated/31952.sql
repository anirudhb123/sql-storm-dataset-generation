WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id,
        m2.title,
        m2.production_year,
        mh.depth + 1
    FROM 
        movie_link m
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    JOIN 
        aka_title m2 ON m.linked_movie_id = m2.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_year,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movies,
    MAX(CASE WHEN mh.depth > 1 THEN 'Yes' ELSE 'No' END) AS has_dependencies
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    c.note IS NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    total_movies DESC
LIMIT 10;
