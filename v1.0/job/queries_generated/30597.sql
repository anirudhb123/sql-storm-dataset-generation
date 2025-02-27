WITH RECURSIVE movie_cast_cte AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        1 AS level
    FROM
        cast_info ci
    WHERE
        ci.nr_order = 1

    UNION ALL

    SELECT
        ci.movie_id,
        ci.person_id,
        mcc.level + 1
    FROM
        cast_info ci
    JOIN
        movie_cast_cte mcc ON ci.movie_id = mcc.movie_id AND ci.nr_order = mcc.level + 1
),
movie_info_with_keywords AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        ARRAY_AGG(mk.keyword) AS keywords
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY
        mt.id
),
person_info_with_roles AS (
    SELECT
        p.id AS person_id,
        a.name,
        ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM
        name a
    JOIN
        person_info pi ON a.imdb_id = pi.person_id
    JOIN
        role_type rt ON pi.info_type_id = rt.id
    GROUP BY
        p.id, a.name
),
ensemble_info AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.person_id) AS cast_count,
        STRING_AGG(DISTINCT p.name, ', ') AS ensemble_cast,
        MAX(CASE WHEN a.title IS NOT NULL THEN a.title ELSE 'Unknown Title' END) AS movie_title
    FROM
        movie_cast_cte mc
    LEFT JOIN
        aka_title a ON mc.movie_id = a.id
    LEFT JOIN
        person_info_with_roles p ON mc.person_id = p.person_id
    GROUP BY
        mc.movie_id
)
SELECT
    ei.movie_id,
    ei.movie_title,
    ei.cast_count,
    ei.ensemble_cast,
    mk.keywords
FROM
    ensemble_info ei
LEFT JOIN
    movie_info_with_keywords mk ON ei.movie_id = mk.movie_id
WHERE
    ei.cast_count > 5
ORDER BY
    ei.cast_count DESC
LIMIT 10;
