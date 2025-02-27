WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000  -- Start with movies from 2000 onwards

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT
    DISTINCT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    MAX(pi.info) AS additional_info,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast_count,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY MAX(pi.info) DESC) AS year_rank
FROM
    aka_name ak
INNER JOIN
    cast_info ci ON ak.person_id = ci.person_id
INNER JOIN
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = 1  -- Assume '1' represents bio info
LEFT JOIN
    complete_cast cc ON mt.id = cc.movie_id
LEFT JOIN
    company_name cn ON cc.movie_id = cn.imdb_id
LEFT JOIN
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE
    ak.name IS NOT NULL
    AND mt.production_year IS NOT NULL
    AND (ci.note LIKE '%main%' OR ci.note IS NULL)  -- Include main roles or NULL notes
GROUP BY
    ak.name,
    mt.title,
    mt.production_year
HAVING
    COUNT(DISTINCT kc.keyword) > 2  -- Only include movies with more than 2 keywords
ORDER BY
    mt.production_year DESC;
This query performs various operations such as recursive CTEs, joins, aggregations, window functions, and filtering based on the specified conditions, making it a robust choice for performance benchmarking.
