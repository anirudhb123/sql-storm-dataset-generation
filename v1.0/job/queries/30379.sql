WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        m.id AS movie_id,
        1 AS level
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
    
    UNION ALL

    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        m.id AS movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        aka_title mt ON m.id = mt.movie_id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
)
SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
             THEN CAST(mi.info AS numeric) END) AS avg_budget,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') 
             THEN CAST(mi.info AS integer) END) AS max_duration
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 AND
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') 
             THEN CAST(mi.info AS integer) END) IS NOT NULL
ORDER BY 
    mh.production_year DESC, total_cast DESC;
