WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::text AS parent_title,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    count(DISTINCT mc.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mh.title || ' (' || mh.production_year || ')', ', ') AS movie_titles,
    SUM(CASE
            WHEN mi.info IS NOT NULL THEN 1
            ELSE 0
        END) AS valid_info_count,
    ROW_NUMBER() OVER(PARTITION BY ak.person_id ORDER BY count(DISTINCT mc.movie_id) DESC) AS rank
FROM
    aka_name ak
LEFT JOIN
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN
    MovieHierarchy mh ON mc.movie_id = mh.movie_id
LEFT JOIN
    movie_info mi ON mc.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')
WHERE
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND (ci.note IS NULL OR ci.note != 'Cameo')
GROUP BY
    ak.id
HAVING
    count(DISTINCT mc.movie_id) > 0
ORDER BY
    rank, movie_count DESC
LIMIT 10;
