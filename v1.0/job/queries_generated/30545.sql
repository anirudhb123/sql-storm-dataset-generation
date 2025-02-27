WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mt.kind AS movie_kind,
        1 AS level
    FROM 
        aka_title m
    JOIN 
        kind_type mt ON m.kind_id = mt.id
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mt.kind AS movie_kind,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.movie_kind,
    COUNT(DISTINCT c.id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    COALESCE(wt.average_runtime, 0) AS avg_runtime,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT OUTER JOIN 
    (SELECT 
        movie_id, 
        AVG(info::int) AS average_runtime
     FROM 
        movie_info 
     WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'runtime')
     GROUP BY 
        movie_id) wt ON mh.movie_id = wt.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.movie_kind
HAVING 
    COUNT(DISTINCT c.id) > 0
ORDER BY 
    avg_runtime DESC;
