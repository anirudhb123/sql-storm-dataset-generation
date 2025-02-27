WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.linked_movie_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', mt.title)
    FROM 
        aka_title mt
    INNER JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mh.movie_id) AS total_cast,
    ARRAY_AGG(DISTINCT a.name) FILTER (WHERE a.name IS NOT NULL) AS cast_names,
    NULLIF(COUNT(DISTINCT ki.keyword) FILTER (WHERE ki.keyword IS NOT NULL), 0) AS total_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword ki ON ki.id = mk.keyword_id
WHERE 
    mh.production_year >= 2000
    AND mh.production_year < 2023
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
ORDER BY 
    mh.production_year DESC, total_cast DESC;

