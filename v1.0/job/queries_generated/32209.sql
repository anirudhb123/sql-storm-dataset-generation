WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    at.title AS movie_title,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS all_akas,
    AVG(REPLACE(TRIM(mk.keyword), '#','')) AS avg_key_length,
    COUNT(DISTINCT mi.info) AS info_count,
    MAX(mk.keyword) AS longest_keyword,
    SUM(CASE 
            WHEN cct.kind IS NOT NULL THEN 1 
            ELSE 0 
        END) AS comp_cast_type_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    comp_cast_type cct ON ci.role_id = cct.id
WHERE 
    mh.depth < 3 -- Limiting the depth to avoid overly large hierarchies
GROUP BY 
    at.title
ORDER BY 
    cast_count DESC, movie_title;
