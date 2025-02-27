WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mv.id, 
        mv.title, 
        mv.production_year, 
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mv ON ml.linked_movie_id = mv.id
    WHERE 
        mh.level < 3  -- Limit depth of recursion
)
SELECT 
    ak.name AS actor_name, 
    COUNT(DISTINCT mh.movie_id) AS movies_participated,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles,
    (SELECT COUNT(DISTINCT ci.movie_id)
     FROM cast_info ci
     WHERE ci.person_id = ak.person_id) AS total_movies_cast
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.md5sum IS NOT NULL
    AND (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mh.movie_id AND mi.info_type_id = 1) > 0
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    movies_participated DESC
LIMIT 10;
