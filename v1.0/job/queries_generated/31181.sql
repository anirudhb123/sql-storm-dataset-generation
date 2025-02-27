WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Starting point for the hierarchy (top-level movies)

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ca.id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    AVG(COALESCE(mo.info_length, 0)) AS avg_movie_info_length,
    MAX(CASE WHEN mk.keyword IS NOT NULL THEN mk.keyword END) AS notable_keyword,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id 
LEFT JOIN 
    cast_info ca ON ca.movie_id = mh.movie_id 
LEFT JOIN 
    aka_name ak ON ak.person_id = ca.person_id 
LEFT JOIN (
    SELECT 
        movie_id, 
        LENGTH(info) AS info_length 
    FROM 
        movie_info 
    UNION ALL
    SELECT 
        movie_id,
        LENGTH(info) AS info_length 
    FROM 
        movie_info_idx
) mo ON mo.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ca.id) > 0 AND 
    mh.level = 1 
ORDER BY 
    mh.production_year DESC, 
    total_cast DESC;
