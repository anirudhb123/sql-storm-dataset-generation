WITH ActorMovieCount AS (
    SELECT
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    GROUP BY
        a.name
),
TopActors AS (
    SELECT
        actor_name
    FROM
        ActorMovieCount
    WHERE
        movie_count > 10
),
ActorMovies AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS release_year,
        k.keyword AS movie_keyword
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.name IN (SELECT actor_name FROM TopActors)
),
ActorMovieInfo AS (
    SELECT
        am.actor_name,
        am.movie_title,
        am.release_year,
        STRING_AGG(DISTINCT am.movie_keyword, ', ') AS keywords
    FROM
        ActorMovies am
    GROUP BY
        am.actor_name, am.movie_title, am.release_year
)
SELECT
    ami.actor_name,
    ami.movie_title,
    ami.release_year,
    ami.keywords
FROM
    ActorMovieInfo ami
ORDER BY
    ami.actor_name, ami.release_year DESC;
