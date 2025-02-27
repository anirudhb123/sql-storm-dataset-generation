WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        path || ml.linked_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    ARRAY_AGG(DISTINCT mh.title ORDER BY mh.level) AS linked_movies,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    mt.production_year >= 2000 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.id, mt.id
ORDER BY 
    keyword_count DESC,
    info_count DESC
LIMIT 50;
