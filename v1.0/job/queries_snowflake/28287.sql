WITH ranked_actors AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY
        a.id, a.name
),
popular_movies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
    HAVING
        COUNT(DISTINCT ci.person_id) > 5
),
actor_movie_join AS (
    SELECT
        ra.actor_id,
        ra.actor_name,
        pm.movie_id,
        pm.movie_title,
        pm.production_year
    FROM
        ranked_actors ra
    JOIN
        cast_info ci ON ra.actor_id = ci.person_id
    JOIN
        popular_movies pm ON ci.movie_id = pm.movie_id
)
SELECT
    am.actor_id,
    am.actor_name,
    am.movie_title,
    am.production_year,
    r.movies_count AS total_movies,
    ROW_NUMBER() OVER (PARTITION BY am.actor_id ORDER BY am.production_year DESC) AS recent_movie_rank
FROM
    actor_movie_join am
JOIN
    ranked_actors r ON am.actor_id = r.actor_id
ORDER BY
    r.movies_count DESC,
    am.production_year DESC;
