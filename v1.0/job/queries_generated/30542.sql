WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = 1  -- Assuming '1' is for movies
    UNION ALL
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS linked_movies_count,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movie_titles,
    ARRAY_AGG(DISTINCT CONCAT_WS(' - ', mt.title, mt.production_year)) AS movies_with_year,
    AVG(m.production_year) AS avg_production_year,
    SUM(CASE WHEN mt.production_year IS NULL THEN 1 ELSE 0 END) AS null_years_count
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name
HAVING
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY
    linked_movies_count DESC;

-- Including a performance limit for benchmarking
EXPLAIN ANALYZE
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = 1
    UNION ALL
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS linked_movies_count,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movie_titles,
    ARRAY_AGG(DISTINCT CONCAT_WS(' - ', mt.title, mt.production_year)) AS movies_with_year,
    AVG(m.production_year) AS avg_production_year,
    SUM(CASE WHEN mt.production_year IS NULL THEN 1 ELSE 0 END) AS null_years_count
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name
HAVING
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY
    linked_movies_count DESC;
