WITH ActorTitles AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        rk.role AS role_name
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
    JOIN
        role_type rk ON c.role_id = rk.id
),
MoviesByYear AS (
    SELECT
        production_year,
        COUNT(*) AS total_movies,
        STRING_AGG(DISTINCT movie_title, ', ') AS movie_titles
    FROM
        ActorTitles
    GROUP BY
        production_year
),
TopActors AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(*) AS movies_count
    FROM
        ActorTitles
    GROUP BY
        actor_id, actor_name
    ORDER BY
        movies_count DESC
    LIMIT 10
)
SELECT
    a.actor_name,
    m.production_year,
    m.total_movies,
    m.movie_titles
FROM
    TopActors a
JOIN
    MoviesByYear m ON a.actor_id IN (
        SELECT DISTINCT actor_id
        FROM ActorTitles
        WHERE production_year = m.production_year
    )
ORDER BY
    m.production_year DESC, a.movies_count DESC;
