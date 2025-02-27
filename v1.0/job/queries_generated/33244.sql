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
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT kc.keyword_id) AS keyword_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 
    AND mh.level > 1 
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_companies mcm 
        WHERE mcm.movie_id = mh.movie_id 
        AND mcm.note IS NULL
    )
ORDER BY 
    mh.production_year DESC, mh.level ASC;
This SQL query performs an analysis of a movie hierarchy using recursive CTEs. It retrieves films linked to each other, counts the unique associated companies, aggregates the names of those companies, filters based on various conditions, and sorts the results by production year and hierarchy level.
