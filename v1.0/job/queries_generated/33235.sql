WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title at
    JOIN 
        movie_link ml ON at.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mh.level,
    mh.title,
    mh.production_year,
    ct.kind AS company_type,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    AVG(pi.info LIKE '%Award%') * 100 AS award_percentage,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    MAX(mi.info) FILTER (WHERE it.info = 'Runtime') AS max_runtime,
    COALESCE(MAX(a.name), 'Unknown') AS lead_actor
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.level, mh.title, mh.production_year, ct.kind
ORDER BY 
    mh.level ASC, mh.production_year DESC;

-- Performance Benchmarking Execution Plan
EXPLAIN ANALYZE 
WITH RECURSIVE MovieHierarchy AS (
    ...
)
SELECT ...

This SQL query utilizes various advanced SQL features such as a recursive Common Table Expression (CTE) to create a movie hierarchy, multiple joins to gather related data, `COUNT`, `AVG`, and `STRING_AGG` aggregate functions to collect statistics and generate a list of actor names, and a `FILTER` clause to conditionally compute values. It also showcases NULL logic with `COALESCE` to handle cases where data may be missing. The `EXPLAIN ANALYZE` command at the end is used to preview the execution plan and performance metrics, which is crucial for benchmarking.
