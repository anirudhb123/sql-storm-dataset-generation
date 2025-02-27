WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year > 2000
    UNION ALL
    SELECT
        mp.movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN
        aka_title m ON m.id = ml.movie_id
)
SELECT
    a.name AS actor_name,
    ARRAY_AGG(DISTINCT m.title) FILTER (WHERE m.production_year IS NOT NULL) AS movies,
    COALESCE(NULLIF(AVG(ci.nr_order), 0), NULL) AS avg_order,
    COUNT(DISTINCT mh.movie_id) AS hierarchy_depth,
    COUNT(DISTINCT CASE WHEN mw.keyword IS NULL THEN 'No Keywords' ELSE mw.keyword END) AS keyword_count
FROM
    aka_name a
LEFT JOIN
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN
    aka_title m ON ci.movie_id = m.id
LEFT JOIN
    movie_keyword mw ON m.id = mw.movie_id
LEFT JOIN
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE
    a.name IS NOT NULL
    AND (a.md5sum IS NULL OR a.md5sum NOT IN (SELECT DISTINCT md5sum FROM aka_name WHERE name LIKE '%test%'))
GROUP BY
    a.name
HAVING
    COUNT(DISTINCT m.id) > 2
    AND (avg_order IS NOT NULL OR hierarchy_depth > 0)
ORDER BY
    keyword_count DESC,
    actor_name ASC;

