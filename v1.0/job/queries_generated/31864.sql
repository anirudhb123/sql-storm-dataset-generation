WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT kw.keyword), 'No Keywords') AS keywords,
    COUNT(DISTINCT cc.subject_id) AS cast_count,
    AVG(CASE WHEN ci.id IS NOT NULL THEN 1 ELSE 0 END) AS has_complete_cast
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    complete_cast cc ON mt.id = cc.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mh.level <= 3
GROUP BY 
    ak.name, mt.title, mt.production_year
ORDER BY 
    movie_title, actor_name;
