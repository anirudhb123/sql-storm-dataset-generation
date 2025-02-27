WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        0 AS level,
        mt.title,
        mt.production_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mh.level + 1,
        at.title,
        at.production_year
    FROM 
        movie_link ml 
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id 
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 3
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.level AS link_level,
    COUNT(DISTINCT ka.keyword) AS keyword_count,
    STRING_AGG(DISTINCT ki.info, ', ') AS additional_info,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title at ON at.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword ka ON mk.keyword_id = ka.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id 
LEFT JOIN 
    info_type ki ON ki.id = mi.info_type_id
WHERE 
    ak.name IS NOT NULL 
    AND ci.nr_order < 5
GROUP BY 
    ak.name, at.title, mh.level
HAVING 
    COUNT(DISTINCT ka.keyword) > 2
ORDER BY 
    NULLIF(mh.level, 0), ak.name ASC, movie_title DESC;
