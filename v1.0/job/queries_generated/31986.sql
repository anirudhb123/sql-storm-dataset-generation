WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1 
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    MAX(CASE WHEN mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN mo.info END) AS box_office,
    COUNT(DISTINCT km.keyword) AS total_keywords,
    COALESCE(SUM(mcl.note IS NOT NULL), 0) AS linked_movies_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mo ON mh.movie_id = mo.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
LEFT JOIN 
    movie_link mcl ON mh.movie_id = mcl.movie_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT cc.person_id) > 5
ORDER BY 
    mh.production_year DESC, mh.title;
