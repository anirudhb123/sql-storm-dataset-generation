WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Sequel: ', m.title) AS title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    STRING_AGG(DISTINCT mh.title, ', ') AS movies,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    COUNT(DISTINCT ci.role_id) AS unique_roles,
    MAX(mh.production_year) AS latest_release_year
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    ak.name ILIKE '%Smith%' OR ak.name ILIKE 'John%'
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    total_movies DESC, latest_release_year DESC;
