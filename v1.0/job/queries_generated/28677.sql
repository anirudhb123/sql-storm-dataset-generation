WITH movie_actor_names AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        ca.nr_order AS actor_order,
        YEAR(CURRENT_DATE) - t.production_year AS years_since_release
    FROM
        aka_name a
    JOIN
        cast_info ca ON a.person_id = ca.person_id
    JOIN
        aka_title t ON ca.movie_id = t.movie_id
    WHERE
        a.name IS NOT NULL
),
movie_info_details AS (
    SELECT
        m.movie_id,
        GROUP_CONCAT(mi.info SEPARATOR ', ') AS movie_infos
    FROM
        movie_info m
    JOIN
        info_type it ON m.info_type_id = it.id
    GROUP BY
        m.movie_id
),
ranked_movies AS (
    SELECT
        ma.actor_name,
        ma.movie_title,
        ma.actor_order,
        ma.years_since_release,
        md.movie_infos,
        RANK() OVER (PARTITION BY ma.actor_name ORDER BY ma.years_since_release DESC) AS release_rank
    FROM
        movie_actor_names ma
    LEFT JOIN
        movie_info_details md ON ma.movie_title = md.movie_id
    WHERE
        ma.actor_order IS NOT NULL
)
SELECT
    actor_name,
    movie_title,
    actor_order,
    years_since_release,
    movie_infos,
    release_rank
FROM
    ranked_movies
WHERE
    release_rank <= 5
ORDER BY
    actor_name, years_since_release DESC;
