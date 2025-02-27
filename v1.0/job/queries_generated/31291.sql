WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level,
        CAST(m.title AS VARCHAR) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title AS movie_title,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mt.title AS VARCHAR) AS path
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.level,
    mh.path,
    ARRAY_AGG(DISTINCT ak.name) AS actors,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    SUM(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 ELSE 0 END) AS company_links
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
WHERE 
    mh.level < 3
GROUP BY 
    mh.movie_id, mh.movie_title, mh.level, mh.path
ORDER BY 
    mh.level, mh.movie_title;
