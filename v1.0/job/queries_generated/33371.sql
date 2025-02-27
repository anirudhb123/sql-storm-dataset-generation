WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 -- Filter for modern movies
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.depth,
    COALESCE(ma.name, 'Unknown') AS main_actor,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_types,
    AVG(pi.info IS NOT NULL::int) AS has_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ma ON cc.subject_id = ma.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id 
WHERE 
    mh.production_year IS NOT NULL 
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.depth, ma.name
ORDER BY 
    mh.production_year DESC, mh.depth ASC;
