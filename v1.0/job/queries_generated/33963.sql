WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.depth + 1
    FROM 
        movie_link ml
        JOIN title m ON ml.linked_movie_id = m.id
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.person_id,
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.movie_title, ', ') AS movies_list,
    MAX(y.production_year) AS last_movie_year,
    SUM(CASE WHEN mk.keyword = 'Action' THEN 1 ELSE 0 END) AS action_movies_count
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    aka_title y ON mh.movie_id = y.id
WHERE 
    ak.name IS NOT NULL 
    AND y.production_year IS NOT NULL
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5 AND 
    MAX(y.production_year) > 2015
ORDER BY 
    total_movies DESC;
