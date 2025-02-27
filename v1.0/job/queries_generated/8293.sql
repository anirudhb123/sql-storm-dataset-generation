WITH Recursive MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    ARRAY_AGG(DISTINCT cn.name) AS character_names,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_types
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name cn ON ci.person_id = cn.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
ORDER BY 
    mh.depth, mh.production_year DESC;
