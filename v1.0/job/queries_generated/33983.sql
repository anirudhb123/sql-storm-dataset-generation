WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        mhl.linked_movie_id AS movie_id,
        l.title,
        l.production_year,
        mh.level + 1
    FROM
        movie_link AS mhl
    JOIN
        title AS l ON mhl.linked_movie_id = l.id
    JOIN
        MovieHierarchy AS mh ON mhl.movie_id = mh.movie_id
),
AggregatedMovies AS (
    SELECT
        mh.title,
        mh.production_year,
        COUNT(ci.id) AS total_casts,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM
        MovieHierarchy AS mh
    LEFT JOIN
        cast_info AS ci ON mh.movie_id = ci.movie_id
    LEFT JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE
        mh.level = 0
    GROUP BY
        mh.title, mh.production_year
)
SELECT
    am.title,
    am.production_year,
    am.total_casts,
    am.actor_names
FROM
    AggregatedMovies AS am
WHERE
    am.total_casts > 2
    AND am.production_year >= 2000
ORDER BY
    am.production_year DESC,
    am.total_casts DESC;

