WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    INNER JOIN
        movie_hierarchy mh ON m.id = mh.movie_id
    WHERE
        mh.level < 5
),
non_null_cast AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM
        cast_info ci
    JOIN
        aka_name a ON a.person_id = ci.person_id
    WHERE
        a.name IS NOT NULL
    GROUP BY
        ci.movie_id, ci.person_id
),
role_statistics AS (
    SELECT
        ci.movie_id,
        MAX(ci.role_count) AS max_roles,
        MIN(ci.role_count) AS min_roles,
        AVG(ci.role_count) AS avg_roles
    FROM
        non_null_cast ci
    GROUP BY
        ci.movie_id
)
SELECT
    m.movie_id,
    m.movie_title,
    m.keyword,
    m.production_year,
    r.max_roles,
    r.min_roles,
    r.avg_roles,
    CASE 
        WHEN r.avg_roles IS NULL THEN 'No casts found'
        ELSE 'Casts available'
    END AS cast_status
FROM
    movie_hierarchy m
LEFT JOIN
    role_statistics r ON m.movie_id = r.movie_id
WHERE
    m.production_year BETWEEN 2000 AND 2020
    AND (m.keyword IS NOT NULL OR r.avg_roles >= 1)
ORDER BY
    m.production_year DESC,
    r.avg_roles DESC NULLS LAST
LIMIT 50;
