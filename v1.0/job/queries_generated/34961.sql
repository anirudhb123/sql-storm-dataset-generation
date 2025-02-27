WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        NULL::integer AS parent_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.movie_id AS parent_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(COALESCE(mo.info_length, 0)) AS avg_info_length,
    MAX(mh.production_year) AS latest_year,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS all_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        LENGTH(info) AS info_length
    FROM 
        movie_info
    WHERE 
        info IS NOT NULL
) mo ON mh.movie_id = mo.movie_id
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movie_count DESC
LIMIT 10;
