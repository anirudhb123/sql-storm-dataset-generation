WITH RECURSIVE MovieHierarchy AS (
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
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rk
    FROM
        MovieHierarchy mh
    WHERE
        mh.level <= 3
),
ActorsWithRoles AS (
    SELECT
        a.id AS actor_id,
        ak.name,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY c.nr_order) AS actor_order
    FROM
        cast_info c
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    JOIN
        role_type r ON c.role_id = r.id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    array_agg(DISTINCT awr.name || ' (' || awr.role || ')') AS actors,
    COUNT(DISTINCT awr.actor_id) AS actor_count
FROM
    RankedMovies rm
LEFT JOIN
    ActorsWithRoles awr ON rm.movie_id = awr.movie_id
WHERE
    rm.rk <= 5
GROUP BY
    rm.movie_id,
    rm.title,
    rm.production_year
ORDER BY
    rm.production_year DESC,
    actor_count DESC;
