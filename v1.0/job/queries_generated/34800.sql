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
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actors_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS has_info 
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.movie_id AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Actor')
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
WHERE 
    mh.level = 1
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    actors_count DESC, mh.production_year DESC
LIMIT 10;

-- Additional benchmark to compare the performance of different join types:
SELECT 
    mt.title,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN ki.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_associated,
    MAX(mk.info) AS most_recent_box_office
FROM 
    aka_title mt
JOIN 
    complete_cast cc ON mt.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    mt.production_year > 2010
GROUP BY 
    mt.title
ORDER BY 
    total_cast DESC, most_recent_box_office DESC;
