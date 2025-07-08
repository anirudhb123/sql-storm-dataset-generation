
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        m.title AS movie_title, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    pi.person_id,
    ak.name AS actor_name,
    LISTAGG(DISTINCT mh.movie_title, ', ') WITHIN GROUP (ORDER BY mh.movie_title) AS movies_linked,
    COUNT(DISTINCT mh.movie_id) AS total_linked_movies,
    AVG(m.production_year) AS avg_production_year
FROM 
    person_info pi
JOIN 
    aka_name ak ON pi.person_id = ak.person_id
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    pi.info_type_id IN (
        SELECT id FROM info_type WHERE info = 'birthdate'
    )
    AND ak.name IS NOT NULL
    AND m.production_year IS NOT NULL
GROUP BY 
    pi.person_id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    total_linked_movies DESC;
