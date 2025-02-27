WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.linked_movie_id = mt.id
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(mi.info) FILTER (WHERE it.info = 'box office') AS box_office,
    SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_companies
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT c.person_id) > 5 AND
    MAX(mi.info) IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    cast_count DESC;
