WITH movie_actor_roles AS (
    SELECT
        c.movie_id,
        a.person_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
), movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        COALESCE(NULLIF(m.production_year, 2023), -1) AS adjusted_year
    FROM
        aka_title m
    WHERE
        m.production_year BETWEEN 2000 AND 2023
),
actors_per_movie AS (
    SELECT
        m.movie_id,
        COUNT(a.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.actor_name, ', ') AS all_actors
    FROM
        movie_actor_roles a
    JOIN
        movie_details m ON a.movie_id = m.movie_id
    GROUP BY
        m.movie_id
),
high_actor_movies AS (
    SELECT
        d.movie_title,
        d.production_year,
        a.actor_count,
        a.all_actors
    FROM
        movie_details d
    JOIN
        actors_per_movie a ON d.movie_id = a.movie_id
    WHERE
        a.actor_count > (
            SELECT
                AVG(actor_count)
            FROM
                actors_per_movie
        )
),
final_output AS (
    SELECT
        h.movie_title,
        h.production_year,
        h.actor_count,
        h.all_actors,
        CASE
            WHEN h.actor_count IS NULL THEN 'No actors found'
            ELSE CONCAT('Starring: ', h.all_actors)
        END AS actor_list,
        RANK() OVER (ORDER BY h.actor_count DESC) AS rank_by_actors
    FROM
        high_actor_movies h
)
SELECT
    movie_title,
    production_year,
    actor_count,
    actor_list,
    rank_by_actors
FROM
    final_output
WHERE
    rank_by_actors <= 10
ORDER BY
    production_year DESC,
    actor_count DESC;
