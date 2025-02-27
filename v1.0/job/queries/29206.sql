WITH MovieActors AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        c.nr_order AS role_order,
        r.role AS role_name,
        t.production_year,
        t.id AS movie_id
    FROM
        cast_info c
        JOIN aka_name a ON c.person_id = a.person_id
        JOIN title t ON c.movie_id = t.id
        JOIN role_type r ON c.role_id = r.id
    WHERE
        t.production_year >= 2000
),
ActorMovieCount AS (
    SELECT
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM
        MovieActors
    GROUP BY
        actor_name
),
TopActors AS (
    SELECT
        actor_name,
        movie_count
    FROM
        ActorMovieCount
    ORDER BY
        movie_count DESC
    LIMIT 10
)
SELECT
    ma.actor_name,
    STRING_AGG(ma.movie_title, '; ') AS movies_list,
    COUNT(DISTINCT ma.movie_id) AS unique_movies_count,
    ma.production_year AS last_movie_year
FROM
    MovieActors ma
JOIN
    TopActors ta ON ma.actor_name = ta.actor_name
GROUP BY
    ma.actor_name, ma.production_year
ORDER BY
    last_movie_year DESC;
