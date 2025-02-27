WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    a.id AS aka_id,
    a.name AS actor_name,
    at.title AS movie_title,
    mh.level AS movie_level,
    COUNT(DISTINCT mr.id) AS total_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MIN(mi.info) FILTER (WHERE mi.info_type_id = 1) AS release_date,
    MAX(mi.info) FILTER (WHERE mi.info_type_id = 2) AS runtime
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON at.id = mi.movie_id
JOIN
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE
    a.name IS NOT NULL
    AND (mi.info IS NOT NULL OR mi.note IS NOT NULL) 
    AND (ci.nr_order IS NOT NULL OR ci.note IS NULL)
GROUP BY
    a.id, a.name, at.title, mh.level
HAVING
    COUNT(DISTINCT mr.id) > 0
ORDER BY
    movie_level DESC, a.actor_name ASC;
