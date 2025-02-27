WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assuming 1 identifies movies

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(mh.level) AS average_linked_level,
    STRING_AGG(DISTINCT mt.title, ', ') AS linked_movies,
    MAX(CASE WHEN pi.info IS NOT NULL THEN pi.info ELSE 'No info' END) AS personal_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Biography'
    )
LEFT JOIN
    aka_title mt ON c.movie_id = mt.id
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    movie_count DESC
LIMIT 10;
