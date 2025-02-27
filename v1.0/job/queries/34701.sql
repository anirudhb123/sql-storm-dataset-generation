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
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m.production_year >= 2000
        AND mh.level < 5  
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS genre,
    SUM(CASE 
            WHEN ci.nr_order IS NULL THEN 1 
            ELSE 0 
        END) AS unnumbered_cast,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    mh.production_year IS NOT NULL
    AND (mi.info_type_id IS NULL OR mi.info != '')  
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5  
ORDER BY 
    mh.production_year, rank;