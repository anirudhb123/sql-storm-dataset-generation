WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        COALESCE(mt.title, 'Untitled') AS movie_title,
        mt.production_year,
        ARRAY[mt.title] AS title_chain,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        COALESCE(at.title, 'Untitled') AS movie_title,
        at.production_year,
        title_chain || at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    ARRAY_LENGTH(mh.title_chain, 1) AS num_links,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    MAX(CASE WHEN ci.role_id IS NULL THEN 'Unknown' ELSE cr.role END) AS role_description,
    SUM(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE 0 END) AS total_info_length,
    COUNT(DISTINCT mk.keyword) AS keyword_count
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
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    role_type cr ON ci.role_id = cr.id
WHERE 
    mh.production_year BETWEEN 1990 AND 2020
    AND (mi.info IS NOT NULL OR ak.name IS NOT NULL)
GROUP BY 
    mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT ak.id) > 1 
    OR SUM(CASE WHEN LENGTH(mi.info) > 200 THEN 1 ELSE 0 END) > 2
ORDER BY 
    num_links DESC, 
    mh.production_year ASC
OFFSET 5 LIMIT 10;
