WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id,
        CONCAT(m.title, ' (part of series)') AS title,
        m.production_year,
        mh.level + 1 AS level
    FROM
        aka_title m
    JOIN
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT
    kh.keyword,
    COUNT(DISTINCT mk.movie_id) AS movie_count,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_count,
    MAX(mh.level) AS max_hierarchy_level
FROM
    movie_keyword mk
JOIN
    keyword kh ON mk.keyword_id = kh.id
LEFT JOIN
    complete_cast cc ON cc.movie_id = mk.movie_id
LEFT JOIN
    cast_info ci ON ci.movie_id = mk.movie_id
LEFT JOIN
    movie_hierarchy mh ON mh.movie_id = mk.movie_id
GROUP BY
    kh.keyword
HAVING
    COUNT(DISTINCT mk.movie_id) > 5
ORDER BY
    movie_count DESC;

-- This query retrieves keywords associated with movies 
-- released since 2000, determining how many unique movies 
-- each keyword is linked to, the average role count from the cast, 
-- and the maximum hierarchy level of potentially linked series. 
-- Only keywords associated with more than 5 movies are returned.
