WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.depth) AS average_depth,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    CASE 
        WHEN COUNT(DISTINCT mh.movie_id) > 10 
            THEN 'Veteran Actor' 
        ELSE 'Rising Star' 
    END AS actor_status
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%dummy%'
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    total_movies DESC;
