WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_details AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        rk.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        role_type rk ON ci.role_id = rk.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
performance_benchmark AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        movie_keywords.keywords,
        cast_details.actor_name,
        cast_details.role,
        cast_details.actor_order
    FROM
        movie_hierarchy mh
    LEFT JOIN
        cast_details ON mh.movie_id = cast_details.movie_id
    LEFT JOIN
        movie_keywords ON mh.movie_id = movie_keywords.movie_id
)
SELECT
    pb.movie_id,
    pb.title,
    pb.production_year,
    pb.keywords,
    pb.actor_name,
    pb.role,
    pb.actor_order
FROM
    performance_benchmark pb
WHERE
    pb.production_year > 2000
    AND pb.role IS NOT NULL
ORDER BY
    pb.production_year DESC,
    pb.actor_order ASC;
