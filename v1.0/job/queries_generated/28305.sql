WITH ActorMovieCount AS (
    SELECT
        a.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    GROUP BY
        a.person_id, a.name
    HAVING
        COUNT(DISTINCT c.movie_id) > 5
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
),
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.actor_name ORDER BY c.actor_name ASC) AS cast_list
    FROM
        title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        TopActors c ON a.name = c.actor_name
    GROUP BY
        t.id, t.title, t.production_year
    ORDER BY
        t.production_year DESC
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_list
FROM
    MovieDetails md
WHERE
    md.production_year >= 2000
ORDER BY
    md.production_year DESC, md.title;
