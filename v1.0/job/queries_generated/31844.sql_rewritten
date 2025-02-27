WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    JOIN
        movie_link ml ON t.id = ml.movie_id
    JOIN
        title m ON ml.linked_movie_id = m.id
    WHERE
        t.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        title m ON ml.linked_movie_id = m.id
    JOIN
        aka_title t ON m.id = t.id
    WHERE
        t.production_year >= 2000 AND mh.level < 3
)

SELECT
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    AVG(mh.level) AS average_hierarchy_level
FROM
    cast_info c
JOIN
    aka_name a ON c.person_id = a.person_id
JOIN
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN
    aka_title t ON c.movie_id = t.id
WHERE
    a.name IS NOT NULL
AND
    a.name NOT LIKE '%test%'
GROUP BY
    a.name
HAVING
    COUNT(DISTINCT c.movie_id) > 2
ORDER BY
    movie_count DESC
LIMIT 10;