WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(mk.keyword, 'Unknown') AS keyword,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(mk.keyword, 'Unknown') AS keyword,
        m.production_year,
        mh.level + 1 AS level
    FROM
        aka_title m
    JOIN
        movie_hierarchy mh ON m.id = mh.movie_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    WHERE
        m.production_year < mh.production_year
),

actor_movie_info AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS recent_role,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    WHERE
        c.note IS NOT NULL
    GROUP BY
        a.name, t.title, t.production_year
)

SELECT
    mh.movie_title,
    mh.production_year,
    COALESCE(a.actor_name, 'No Actor') AS actor_name,
    mh.keyword,
    calculated_revenue,
    CASE
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Noughties'
        ELSE 'New Era'
    END AS era,
    (SELECT COUNT(*) FROM info_type it JOIN movie_info mi ON it.id = mi.info_type_id WHERE mi.movie_id = mh.movie_id) AS info_count
FROM
    movie_hierarchy mh
LEFT JOIN
    actor_movie_info a ON mh.movie_title = a.movie_title
LEFT JOIN LATERAL (
    SELECT SUM(amount) AS calculated_revenue
    FROM (
        SELECT COALESCE(CAST(info AS numeric), 0) AS amount
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'BoxOffice' AND mi.movie_id = mh.movie_id
    ) AS revenue
) AS revenue_info ON TRUE
WHERE
    mh.level <= 3 AND (mh.keyword IS NOT NULL OR mh.keyword != '')
ORDER BY
    mh.production_year DESC,
    a.keyword_count DESC,
    mh.movie_title;


