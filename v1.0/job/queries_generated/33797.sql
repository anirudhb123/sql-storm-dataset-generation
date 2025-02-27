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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT mk.movie_id) AS movie_count,
    AVG(CASE WHEN a.production_year IS NOT NULL THEN a.production_year END) AS average_production_year,
    STRING_AGG(DISTINCT a.title, ', ') AS movies_list
FROM 
    movie_keyword mk
LEFT JOIN 
    aka_title a ON mk.movie_id = a.id
LEFT JOIN 
    MovieHierarchy mh ON a.id = mh.movie_id
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mk.movie_id) > 5
ORDER BY 
    movie_count DESC;

-- Performance metrics
EXPLAIN ANALYZE
SELECT 
    mk.keyword,
    COUNT(DISTINCT mk.movie_id) AS movie_count,
    AVG(CASE WHEN a.production_year IS NOT NULL THEN a.production_year END) AS average_production_year,
    STRING_AGG(DISTINCT a.title, ', ') AS movies_list
FROM 
    movie_keyword mk
LEFT JOIN 
    aka_title a ON mk.movie_id = a.id
LEFT JOIN 
    MovieHierarchy mh ON a.id = mh.movie_id
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mk.movie_id) > 5
ORDER BY 
    movie_count DESC;
