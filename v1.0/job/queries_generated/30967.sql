WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        c.movie_id,
        1 AS level
    FROM
        cast_info c
    WHERE
        c.role_id = (SELECT id FROM role_type WHERE role = 'Actor')

    UNION ALL

    SELECT
        c.person_id,
        c.movie_id,
        ah.level + 1
    FROM
        cast_info c
    INNER JOIN ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE
        c.person_id <> ah.person_id
),
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_actors,
        AVG(mi.rating) AS average_rating
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        movie_info mi ON t.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        t.id, t.title, t.production_year
),
LatestMovies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.all_actors,
        md.average_rating,
        ROW_NUMBER() OVER (PARTITION BY md.actor_count ORDER BY md.production_year DESC) AS rn
    FROM
        MovieDetails md
    WHERE
        md.production_year >= 2000
)
SELECT
    lm.movie_id,
    lm.title,
    lm.production_year,
    lm.actor_count,
    lm.all_actors,
    lm.average_rating
FROM
    LatestMovies lm
WHERE
    lm.rn <= 3
ORDER BY
    lm.actor_count DESC,
    lm.production_year DESC
WITH ROLLUP;
