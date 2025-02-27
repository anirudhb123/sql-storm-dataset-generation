WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorsWithCount AS (
    SELECT
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    GROUP BY
        a.name
),
MoviesWithActors AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT a.id) AS actor_count,
        COALESCE(NULLIF(SUM(CASE WHEN a.name IS NOT NULL THEN 1 ELSE 0 END), 0), 1) AS valid_actor_count
    FROM
        RankedMovies m
    LEFT JOIN
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        m.movie_id, m.title, m.production_year
)
SELECT
    r.production_year,
    r.movie_count,
    m.title,
    m.actor_count,
    a.movie_count AS actor_movie_count,
    CASE
        WHEN m.actor_count > 0 THEN ROUND(cast(m.actor_count AS float) / a.movie_count, 2)
        ELSE NULL
    END AS avg_actors_per_movie,
    COALESCE(GREATEST(m.valid_actor_count, 1), 1) AS effective_actor_count
FROM
    RankedMovies r
JOIN
    MoviesWithActors m ON r.movie_id = m.movie_id
JOIN
    ActorsWithCount a ON m.actor_count = a.movie_count
WHERE
    r.rn <= 10
  AND
    m.actor_count > 0
ORDER BY
    r.production_year DESC,
    m.actor_count DESC;
