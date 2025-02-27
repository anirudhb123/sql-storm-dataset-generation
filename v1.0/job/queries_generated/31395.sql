WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS number_of_movies,
    STRING_AGG(DISTINCT CONCAT(mh.title, ' (', mh.production_year, ')'), ', ') AS movie_titles,
    AVG(CASE 
            WHEN mt.info_type_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS avg_has_info,
    MAX(mh.level) AS max_relation_level
FROM 
    MovieHierarchy AS mh
JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name AS a ON cc.subject_id = a.person_id
LEFT JOIN 
    movie_info AS mt ON mh.movie_id = mt.movie_id AND mt.note IS NOT NULL
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    number_of_movies DESC
LIMIT 10;
