WITH ranked_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title m
    JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id, m.title, m.production_year
),
actors_info AS (
    SELECT
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_production_year
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title m ON c.movie_id = m.id
    GROUP BY
        a.id, a.name
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    ai.actor_id,
    ai.name,
    ai.movie_count,
    ai.avg_production_year
FROM
    ranked_movies r
LEFT JOIN
    actors_info ai ON r.rank <= 5 AND r.movie_id = ai.actor_id
WHERE
    r.production_year IS NOT NULL
ORDER BY
    r.production_year DESC, r.rank
LIMIT 50;
