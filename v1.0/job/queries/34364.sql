
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        NULL AS parent_title,
        0 AS level
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        mh.title AS parent_title,
        mh.level + 1 AS level
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_title,
    mh.level,
    COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
    STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') AS cast_details,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') THEN CAST(mi.info AS INTEGER) END) AS avg_duration
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.parent_title, mh.level
HAVING 
    mh.level > 0 OR COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mh.production_year DESC, 
    mh.title;
