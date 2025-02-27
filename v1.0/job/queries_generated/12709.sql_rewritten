WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        a.person_id
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        aka_title at ON mk.movie_id = at.movie_id
    JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year IS NOT NULL
),
AggregatedInfo AS (
    SELECT
        production_year,
        COUNT(DISTINCT title_id) AS total_titles,
        COUNT(DISTINCT actor_name) AS total_actors
    FROM
        RankedTitles
    GROUP BY
        production_year
)
SELECT
    production_year,
    total_titles,
    total_actors
FROM
    AggregatedInfo
ORDER BY
    production_year DESC;