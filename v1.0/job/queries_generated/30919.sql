WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1,
        path || ml.linked_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS co_actors,
    SUM(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE 0 END) AS total_info_length,
    AVG(CASE WHEN mc.type = 'Production' THEN mc.status_id END) AS avg_production_status,
    ROW_NUMBER() OVER (PARTITION BY mh.created_year ORDER BY mh.actor_count DESC) AS rank_within_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
JOIN 
    aka_name cn ON ci.person_id = cn.person_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    mh.production_year DESC, actor_count DESC;
