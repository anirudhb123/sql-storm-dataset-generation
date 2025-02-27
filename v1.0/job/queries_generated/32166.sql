WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Considering movies from the year 2000 onwards
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON mt.id = ml.linked_movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS titles,
    AVG(mk.keyword_count) AS avg_keywords,
    MAX(mt.production_year) AS last_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    (
        SELECT 
            mk.movie_id, 
            COUNT(mk.keyword_id) AS keyword_count
        FROM 
            movie_keyword mk
        GROUP BY 
            mk.movie_id
    ) AS mk ON mk.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> '' -- Filtering out NULL or empty names
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2 -- Including actors with more than 2 movies
ORDER BY 
    movie_count DESC,
    ak.name ASC;
