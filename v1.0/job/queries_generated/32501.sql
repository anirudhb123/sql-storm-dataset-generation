WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(ci.id) AS cast_count,
    STRING_AGG(DISTINCT an.name, ', ') AS actors,
    MAX(CASE WHEN it.info = 'Budget' THEN mi.info END) AS budget,
    COALESCE(MAX(mk.keyword), 'No keywords') AS primary_keyword
FROM
    movie_hierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    info_type it ON mi.info_type_id = it.id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING
    COUNT(ci.id) > 2
ORDER BY
    mh.production_year DESC, mh.title;
