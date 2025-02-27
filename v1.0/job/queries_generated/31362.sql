WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    COUNT(cc.id) AS cast_count,
    STRING_AGG(DISTINCT an.name, ', ') AS actors,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN mi.info END) AS rating,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Duration') THEN CAST(mi.info AS FLOAT) END) AS avg_duration,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Rating', 'Duration'))
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    mh.depth < 3
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.kind_id
HAVING
    COUNT(cc.id) > 0
ORDER BY
    avg_duration DESC NULLS LAST;
