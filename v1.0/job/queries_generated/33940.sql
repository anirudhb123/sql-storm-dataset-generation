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
        aka_title AS at ON at.id = ml.linked_movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    AVG(mh.level * m.production_year) AS weighted_average_year,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    MAX(CASE 
        WHEN ci.note IS NOT NULL THEN 'Has Notes' ELSE 'No Notes' 
    END) AS notes_status
FROM 
    aka_name AS ak
LEFT JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy AS mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_title AS m ON mh.movie_id = m.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
GROUP BY 
    ak.name
HAVING 
    COUNT(m.movie_id) > 1
ORDER BY 
    movie_count DESC
LIMIT 10;
