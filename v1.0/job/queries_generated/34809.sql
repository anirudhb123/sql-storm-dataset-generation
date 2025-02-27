WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
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
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mw.level AS movie_level,
    COALESCE(ci.note, 'No role') AS role_description,
    COUNT(DISTINCT mw.movie_id) OVER (PARTITION BY ak.name) AS movies_count,
    STRING_AGG(DISTINCT it.info, '; ') FILTER (WHERE it.info IS NOT NULL) AS additional_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mw ON ci.movie_id = mw.movie_id
LEFT JOIN 
    movie_info mi ON mw.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
WHERE 
    mw.production_year >= 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mw.level, ci.note
ORDER BY 
    movies_count DESC, mw.level ASC;
