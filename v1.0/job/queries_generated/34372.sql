WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link m
    JOIN 
        aka_title at ON m.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON m.movie_id = mh.movie_id
)
SELECT 
    ak.person_id,
    ak.name,
    mh.title,
    mh.production_year,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS roles_count,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length,
    STRING_AGG(DISTINCT mi.info, ', ') AS info_summary,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.person_id,
    ak.name,
    mh.title,
    mh.production_year
HAVING 
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) >= 1
ORDER BY 
    roles_count DESC,
    mh.production_year DESC,
    ak.name;
