WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
)

SELECT 
    name.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.level) AS avg_link_depth,
    STRING_AGG(DISTINCT mt.title, ', ') AS linked_movies,
    FIRST_VALUE(mh.title) OVER (PARTITION BY name.id ORDER BY mh.production_year DESC) AS latest_movie,
    CASE 
        WHEN COUNT(DISTINCT mh.movie_id) > 10 THEN 'High Performer'
        WHEN COUNT(DISTINCT mh.movie_id) BETWEEN 5 AND 10 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    aka_name name
INNER JOIN 
    cast_info ci ON name.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
INNER JOIN 
    title mt ON ci.movie_id = mt.id
WHERE 
    name.name IS NOT NULL
GROUP BY 
    name.id
HAVING 
    COUNT(DISTINCT mt.id) > 0
ORDER BY 
    total_movies DESC;
