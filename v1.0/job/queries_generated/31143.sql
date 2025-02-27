WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id, 
        CONCAT('Sequel to: ', mh.title) AS title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    m.id AS movie_id,
    m.title,
    COUNT(DISTINCT c.person_id) AS cast_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT a.name) AS actor_names,
    AVG(mi.production_year) AS avg_production_year,
    CASE 
        WHEN mi.info IS NULL THEN 'No info available'
        ELSE mi.info
    END AS movie_info
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    c.nr_order < 5 
    AND (mi.note IS NULL OR mi.note NOT LIKE '%deleted%')
GROUP BY 
    m.id, mh.title, mi.info
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    avg_production_year DESC, 
    movie_id 
LIMIT 50;

-- Include debugging statement for performance metrics.
EXPLAIN ANALYZE
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        CONCAT('Sequel to: ', mh.title) AS title,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    m.id AS movie_id,
    m.title,
    COUNT(DISTINCT c.person_id) AS cast_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT a.name) AS actor_names,
    AVG(mi.production_year) AS avg_production_year,
    CASE 
        WHEN mi.info IS NULL THEN 'No info available'
        ELSE mi.info
    END AS movie_info
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    c.nr_order < 5 
    AND (mi.note IS NULL OR mi.note NOT LIKE '%deleted%')
GROUP BY 
    m.id, mh.title, mi.info
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    avg_production_year DESC, 
    movie_id 
LIMIT 50;
