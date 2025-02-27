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
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM
        movie_hierarchy mh
),
top_ranked_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.level
    FROM
        ranked_movies rm
    WHERE
        rm.rank <= 5
),
cast_info_extended AS (
    SELECT
        ci.movie_id,
        GROUP_CONCAT(DISTINCT ak.name) AS actors,
        COUNT(*) AS actor_count
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
)
SELECT
    trm.title,
    trm.production_year,
    trm.level,
    ce.actors,
    ce.actor_count,
    COALESCE(SUM(mv.info_type_id), 0) AS total_movie_info,
    COALESCE(SUM(CASE WHEN mv.info_type_id IS NULL THEN 1 ELSE 0 END), 0) AS null_info_count
FROM
    top_ranked_movies trm
LEFT JOIN
    cast_info_extended ce ON trm.movie_id = ce.movie_id
LEFT JOIN
    movie_info mv ON trm.movie_id = mv.movie_id
WHERE
    trm.production_year IS NOT NULL
GROUP BY
    trm.title, trm.production_year, trm.level, ce.actors, ce.actor_count
ORDER BY
    trm.level, trm.production_year DESC;
