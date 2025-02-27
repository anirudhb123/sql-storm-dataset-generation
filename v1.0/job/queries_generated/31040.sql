WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link AS ml
    JOIN
        aka_title AS mt ON ml.linked_movie_id = mt.id
    JOIN
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
),
EnhancedMovies AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        COUNT(cc.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        MovieHierarchy AS mh
    LEFT JOIN
        complete_cast AS cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY
        mh.movie_id, mh.movie_title, mh.production_year, mh.level
),
MovieInfoStats AS (
    SELECT
        em.movie_id,
        em.movie_title,
        em.production_year,
        em.level,
        em.cast_count,
        em.actor_names,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        COALESCE(mi.info_count, 0) AS info_count
    FROM
        EnhancedMovies AS em
    LEFT JOIN (
        SELECT
            movie_id,
            COUNT(DISTINCT keyword_id) AS keyword_count
        FROM
            movie_keyword
        GROUP BY
            movie_id
    ) AS mk ON em.movie_id = mk.movie_id
    LEFT JOIN (
        SELECT
            movie_id,
            COUNT(*) AS info_count
        FROM
            movie_info
        GROUP BY
            movie_id
    ) AS mi ON em.movie_id = mi.movie_id
)
SELECT
    movie_id,
    movie_title,
    production_year,
    level,
    cast_count,
    actor_names,
    keyword_count,
    info_count,
    CASE
        WHEN cast_count > 0 AND keyword_count = 0 THEN 'Low Keywords'
        WHEN cast_count > 5 AND info_count > 0 THEN 'High Cast and Info'
        WHEN level > 2 THEN 'Sequels'
        ELSE 'Standard'
    END AS classification
FROM
    MovieInfoStats
ORDER BY
    production_year DESC,
    level,
    cast_count DESC;
