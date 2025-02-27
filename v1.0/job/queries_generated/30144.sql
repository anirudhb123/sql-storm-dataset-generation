WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM
        aka_title e
    JOIN
        movie_hierarchy mh ON mh.movie_id = e.episode_of_id
),
cast_ranked AS (
    SELECT
        ci.person_id,
        ci.movie_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM
        cast_info ci
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'Unknown') AS actors,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COUNT(DISTINCT rc.person_id) AS unique_cast_count,
    AVG(CASE WHEN rc.role_rank = 1 THEN 1 ELSE 0 END) AS main_actor_percentage
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_ranked rc ON mh.movie_id = rc.movie_id
LEFT JOIN
    aka_name ak ON rc.person_id = ak.person_id
LEFT JOIN
    keyword_counts kc ON mh.movie_id = kc.movie_id
WHERE
    mh.production_year >= 2000
GROUP BY
    mh.movie_id, mh.title, mh.production_year
ORDER BY
    mh.production_year DESC, mh.title;
