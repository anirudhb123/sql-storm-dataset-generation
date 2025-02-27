WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.person_id,
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movies_in_hierarchy,
    ARRAY_AGG(DISTINCT mh.movie_title) AS movie_titles,
    AVG(CASE 
        WHEN m.production_year IS NOT NULL THEN m.production_year 
        ELSE NULL 
    END) AS avg_production_year,
    STRING_AGG(DISTINCT mi.info, '; ') AS additional_info
FROM 
    aka_name AS ak
LEFT JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy AS mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    title AS m ON mh.movie_id = m.id
LEFT JOIN 
    movie_info AS mi ON m.id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    movies_in_hierarchy DESC, avg_production_year DESC
LIMIT 50;

