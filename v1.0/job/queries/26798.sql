WITH movie_actor_counts AS (
    SELECT
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        aka_title m
    JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id
),
keyword_counts AS (
    SELECT
        m.id AS movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        aka_title m
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),
detailed_movie_info AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mac.actor_count, 0) AS actor_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        m.production_year,
        STRING_AGG(DISTINCT p.info, ', ') AS person_info
    FROM
        aka_title m
    LEFT JOIN
        movie_actor_counts mac ON m.id = mac.movie_id
    LEFT JOIN
        keyword_counts kc ON m.id = kc.movie_id
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN
        person_info p ON m.id = p.person_id
    GROUP BY
        m.id, m.title, mac.actor_count, kc.keyword_count, m.production_year
)
SELECT
    d.movie_id,
    d.title,
    d.actor_count,
    d.keyword_count,
    d.production_year,
    d.person_info
FROM
    detailed_movie_info d
WHERE
    d.actor_count > 5 AND
    d.keyword_count > 3 AND
    d.production_year >= 2000
ORDER BY
    d.production_year DESC, d.actor_count DESC;