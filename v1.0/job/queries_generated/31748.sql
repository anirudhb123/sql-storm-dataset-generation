WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT
        m2.id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.person_id,
    ak.name AS aka_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_movie_year,
    STRING_AGG(DISTINCT m.title, ', ') AS linked_movies,
    SUM(CASE 
        WHEN ci.note IS NOT NULL THEN 1
        ELSE 0 
    END) AS roles_with_notes,
    MAX(CASE WHEN ci.person_role_id IS NOT NULL THEN 'Has Role' ELSE 'No Role' END) AS role_status
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title m ON ci.movie_id = m.id
WHERE 
    ak.name_pcode_cf IS NOT NULL
    AND m.production_year IS NOT NULL
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;
