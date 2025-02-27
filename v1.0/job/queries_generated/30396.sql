WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature') -- Assuming 'feature' is a valid kind
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(cc.id) AS cast_count,
    ARRAY_AGG(DISTINCT ak.name) AS actors,
    AVG(mi.info::FLOAT) FILTER (WHERE it.info = 'rating') AS avg_rating, 
    string_agg(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS notes_present
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(cc.id) > 0 AND avg_rating IS NOT NULL
ORDER BY 
    mh.production_year DESC, cast_count DESC;
