WITH ranked_movies AS (
    SELECT
        a.title AS movie_title,
        c.name AS actor_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title a
    JOIN
        movie_info mi ON a.id = mi.movie_id
    JOIN
        title t ON a.movie_id = t.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name an ON ci.person_id = an.person_id
    JOIN
        name n ON an.person_id = n.imdb_id
    WHERE
        t.production_year IS NOT NULL
        AND n.gender = 'F'
),
top_female_actors AS (
    SELECT
        actor_name,
        COUNT(movie_title) AS total_movies
    FROM
        ranked_movies
    WHERE
        year_rank <= 5
    GROUP BY
        actor_name
)
SELECT
    tf.actor_name,
    tf.total_movies,
    MAX(r.production_year) AS latest_movie_year
FROM
    top_female_actors tf
JOIN
    ranked_movies r ON tf.actor_name = r.actor_name
GROUP BY
    tf.actor_name, tf.total_movies
ORDER BY
    total_movies DESC;
