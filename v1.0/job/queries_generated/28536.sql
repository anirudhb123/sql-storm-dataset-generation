WITH movie_name_summary AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        COUNT(c.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.id
    JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
        AND a.name IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year, a.name
),
average_actor_count AS (
    SELECT
        AVG(actor_count) AS avg_actor_count
    FROM
        movie_name_summary
),
well_received_movies AS (
    SELECT
        m.movie_id,
        m.movie_title,
        m.production_year,
        m.actor_name,
        m.actor_count,
        m.keywords,
        a.avg_actor_count
    FROM
        movie_name_summary m
    CROSS JOIN
        average_actor_count a
    WHERE
        m.actor_count > a.avg_actor_count 
        AND m.production_year >= 2010
)
SELECT
    w.movie_title,
    w.production_year,
    w.actor_name,
    w.actor_count,
    w.keywords
FROM
    well_received_movies w
ORDER BY
    w.production_year DESC, 
    w.actor_count DESC
LIMIT 10;
