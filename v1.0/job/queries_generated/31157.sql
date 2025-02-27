WITH RECURSIVE MovieHierarchies AS (
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
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchies mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    SUM(CASE WHEN mt.production_year > 2000 THEN 1 ELSE 0 END) AS movies_post_2000,
    ARRAY_AGG(DISTINCT mt.title) FILTER (WHERE mt.title IS NOT NULL) AS movie_titles
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    MovieHierarchies mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC;
