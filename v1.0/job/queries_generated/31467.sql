WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.movie_id = mt.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS movies,
    AVG(CASE WHEN mi.info IS NOT NULL THEN mi.info::numeric END) AS avg_rating,
    MAX(CASE WHEN mi.info IS NOT NULL THEN mi.info END) AS highest_rating,
    MIN(CASE WHEN mi.info IS NOT NULL THEN mi.info END) AS lowest_rating
FROM
    cast_info c
JOIN
    aka_name a ON c.person_id = a.person_id
LEFT JOIN
    movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
JOIN
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    a.name IS NOT NULL
    AND c.note IS NULL
    AND mh.level <= 2
GROUP BY
    a.name
HAVING
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY
    movie_count DESC;
