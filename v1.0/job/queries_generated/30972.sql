WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY[m.title] AS title_path,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.title_path || mt.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON mt.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.title_path,
    mh.depth,
    COALESCE(cast_count.cast_count, 0) AS cast_count,
    COALESCE(ki.keyword_count, 0) AS keyword_count,
    COALESCE(mci.company_count, 0) AS company_count,
    CASE 
        WHEN mh.depth > 5 THEN 'Deeply Nested'
        WHEN mh.depth > 0 THEN 'Shallow'
        ELSE 'Standalone'
    END AS hierarchy_type
FROM 
    movie_hierarchy mh
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(*) AS cast_count 
    FROM 
        cast_info 
    GROUP BY 
        movie_id
) cast_count ON mh.movie_id = cast_count.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(*) AS keyword_count 
    FROM 
        movie_keyword 
    GROUP BY 
        movie_id
) ki ON mh.movie_id = ki.movie_id
LEFT JOIN (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
) mci ON mh.movie_id = mci.movie_id
ORDER BY 
    mh.depth DESC, 
    mh.movie_id
LIMIT 100;

