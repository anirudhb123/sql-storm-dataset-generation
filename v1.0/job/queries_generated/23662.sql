WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(1000)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(1000))
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    COALESCE(c.role_id, 0) AS role_id,
    COUNT( DISTINCT mh.path) OVER (PARTITION BY ak.name ORDER BY a.production_year) AS movie_count,
    MAX(mh.level) AS max_linked_depth,
    STRING_AGG(DISTINCT mh.path, ' | ') AS all_movies_linked
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title a ON c.movie_id = a.id
LEFT JOIN 
    MovieHierarchy mh ON a.id = mh.movie_id
GROUP BY 
    ak.name, a.title, a.production_year, c.role_id
HAVING 
    COUNT(DISTINCT mh.path) > 1 OR max_linked_depth IS NULL 
ORDER BY 
    movie_count DESC, a.production_year DESC;
