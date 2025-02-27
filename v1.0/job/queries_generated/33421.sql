WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.id AS root_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.root_id
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mk.keyword AS Keyword,
    COUNT(DISTINCT c.person_id) AS Total_Cast,
    AVG(year_production) AS Avg_Production_Year,
    STRING_AGG(DISTINCT a.name, ', ') AS Cast_Names
FROM 
    movie_keyword mk
JOIN 
    movie_info mi ON mk.movie_id = mi.movie_id
JOIN 
    aka_title a ON mk.movie_id = a.id
LEFT JOIN 
    (SELECT 
        c.movie_id, 
        t.production_year AS year_production
     FROM 
        complete_cast c
     JOIN 
        aka_title t ON c.movie_id = t.id) AS movie_details ON a.id = movie_details.movie_id
JOIN 
    cast_info c ON a.id = c.movie_id
WHERE 
    mi.info_type_id IN (
        SELECT id FROM info_type WHERE info LIKE '%rating%'
    )
    AND a.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    Avg_Production_Year DESC
LIMIT 10;

-- Additional benchmarking aspect
EXPLAIN ANALYZE
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.id AS root_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.root_id
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mk.keyword AS Keyword,
    COUNT(DISTINCT c.person_id) AS Total_Cast,
    AVG(year_production) AS Avg_Production_Year,
    STRING_AGG(DISTINCT a.name, ', ') AS Cast_Names
FROM 
    movie_keyword mk
JOIN 
    movie_info mi ON mk.movie_id = mi.movie_id
JOIN 
    aka_title a ON mk.movie_id = a.id
LEFT JOIN 
    (SELECT 
        c.movie_id, 
        t.production_year AS year_production
     FROM 
        complete_cast c
     JOIN 
        aka_title t ON c.movie_id = t.id) AS movie_details ON a.id = movie_details.movie_id
JOIN 
    cast_info c ON a.id = c.movie_id
WHERE 
    mi.info_type_id IN (
        SELECT id FROM info_type WHERE info LIKE '%rating%'
    )
    AND a.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    Avg_Production_Year DESC
LIMIT 10;
This query structure incorporates various SQL constructs including Common Table Expressions (CTE) for recursive relationships, outer joins for linking movie details, and aggregate functions with `GROUP BY` and `HAVING` clauses. It benchmarks performance using the `EXPLAIN ANALYZE` command to measure query performance.
