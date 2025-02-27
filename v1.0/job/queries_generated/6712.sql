WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    p.name AS person_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MAX(mh.production_year) AS latest_production_year
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name p ON cc.subject_id = p.person_id
WHERE 
    p.name IS NOT NULL
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    total_movies DESC, latest_production_year DESC
LIMIT 10;
