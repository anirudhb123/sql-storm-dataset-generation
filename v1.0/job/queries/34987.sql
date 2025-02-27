WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mv.movie_id,
        mv.title,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mv.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title mv ON ml.linked_movie_id = mv.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mv.production_year >= 2000
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    AVG(m.production_year) AS average_movie_year,
    STRING_AGG(DISTINCT mh.path, ', ') AS linked_movies,
    MAX(CASE WHEN m.production_year IS NULL THEN 'Unknown Year' ELSE CAST(m.production_year AS VARCHAR(4)) END) AS latest_movie_year
FROM 
    cast_info cc
JOIN 
    aka_name a ON cc.person_id = a.person_id
JOIN 
    aka_title m ON cc.movie_id = m.id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT cc.movie_id) > 5
ORDER BY 
    total_movies DESC;
