WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.id IS NOT NULL
    UNION ALL
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
),
top_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        COUNT(ci.person_id) AS cast_count
    FROM
        movie_hierarchy mh
    LEFT JOIN
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year, mh.depth
),
ranked_movies AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM
        top_movies
    WHERE
        production_year IS NOT NULL
)
SELECT
    ak.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year,
    mv.depth,
    mv.cast_count
FROM
    ranked_movies mv
JOIN
    cast_info ci ON mv.movie_id = ci.movie_id
JOIN
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    mv.rank_within_year <= 5
    AND (ci.note IS NULL OR ci.note NOT LIKE '%uncredited%')
ORDER BY
    mv.production_year DESC,
    mv.cast_count DESC;
