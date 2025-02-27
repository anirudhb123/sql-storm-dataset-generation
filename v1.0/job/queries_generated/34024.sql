WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000
    UNION ALL
    SELECT
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title t ON ml.linked_movie_id = t.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

RankedCast AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
),

MovieInfo AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_details
    FROM
        movie_info mi
    JOIN
        aka_title m ON mi.movie_id = m.id
    GROUP BY
        m.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ri.actor_name, 'No cast') AS leading_actor,
    COALESCE(mi.movie_details, 'No details available') AS additional_info,
    mh.depth,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM
    MovieHierarchy mh
LEFT JOIN
    RankedCast ri ON mh.movie_id = ri.movie_id AND ri.rank = 1
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY
    mh.movie_id, mh.title, mh.production_year, ri.actor_name, mi.movie_details, mh.depth
ORDER BY
    mh.production_year DESC, mh.title ASC;
