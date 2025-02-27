WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    mci.kind AS company_type,
    COUNT(DISTINCT ci.id) AS cast_count,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_note_ratio,
    STRING_AGG(DISTINCT na.name, ', ') AS actors
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type mci ON mc.company_type_id = mci.id
LEFT JOIN 
    aka_name na ON ci.person_id = na.person_id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mci.kind
HAVING 
    COUNT(DISTINCT ci.id) > 0
ORDER BY 
    mh.production_year DESC, mh.title;
