WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        1 AS level,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        at.title,
        mh.level + 1,
        path || at.title
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    array_to_string(mh.path, ' -> ') AS movie_path,
    COUNT(DISTINCT c.person_id) AS num_actors,
    AVG(mi.info->>'duration') AS avg_duration,
    MIN(CASE WHEN c.nr_order IS NULL THEN 'Unknown' ELSE 'Known' END) AS actor_status
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration')
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id,
    mh.title,
    mh.level
ORDER BY 
    num_actors DESC, 
    avg_duration DESC NULLS LAST;
