WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
KeyWordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS num_keywords
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cc.num_cast, 0) AS total_cast,
    COALESCE(kc.num_keywords, 0) AS total_keywords,
    mh.level
FROM
    MovieHierarchy mh
LEFT JOIN
    CastCounts cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    KeyWordCounts kc ON mh.movie_id = kc.movie_id
WHERE
    mh.production_year >= 2000
ORDER BY
    mh.production_year DESC,
    total_cast DESC,
    total_keywords DESC;
