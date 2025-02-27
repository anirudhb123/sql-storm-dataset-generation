WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year IS NOT NULL
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(array_length(mh.path, 1), 0) AS path_length,
    COUNT(DISTINCT cc.id) AS cast_count,
    SUM(CASE WHEN cc.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS cast_names,
    AVG(p.runtime) AS avg_runtime,
    stddev_pop(p.runtime) AS runtime_std_dev
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name cn ON cn.person_id = cc.person_id
LEFT JOIN 
    (SELECT movie_id, AVG(runtime) AS runtime FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'runtime') GROUP BY movie_id) p ON p.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT cc.id) > 5 
    AND COALESCE(AVG(p.runtime), 0) > 60
ORDER BY 
    mh.production_year DESC, 
    cast_count DESC;
