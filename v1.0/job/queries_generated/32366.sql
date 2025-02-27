WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS year_count
    FROM
        movie_hierarchy mh
),
movie_cast AS (
    SELECT
        m.id AS movie_id,
        a.name AS actor_name,
        r.role AS role,
        COUNT(c.id) AS cast_count
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON r.id = c.role_id
    JOIN aka_title m ON c.movie_id = m.id
    GROUP BY
        m.id, a.name, r.role
),
movie_info_with_year AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No additional info') AS info,
        COALESCE(a.actor_count, 0) AS actor_count
    FROM
        aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN (
        SELECT
            movie_id,
            COUNT(*) AS actor_count
        FROM
            cast_info
        GROUP BY
            movie_id
    ) a ON a.movie_id = m.id
)
SELECT
    r.title,
    r.production_year,
    r.title_rank,
    r.year_count,
    COALESCE(mc.actor_name, 'Unknown Actor') AS actor_name,
    mc.role,
    mc.cast_count,
    CASE
        WHEN r.year_count > 5 THEN 'Popular Year'
        ELSE 'Less Popular Year'
    END AS popularity,
    mi.info
FROM
    ranked_movies r
LEFT JOIN movie_cast mc ON r.movie_id = mc.movie_id
LEFT JOIN movie_info_with_year mi ON r.movie_id = mi.movie_id
WHERE
    r.production_year IS NOT NULL
ORDER BY
    r.production_year DESC,
    r.title_rank;
