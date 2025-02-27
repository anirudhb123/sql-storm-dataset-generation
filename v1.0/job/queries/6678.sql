WITH RecursiveMovieActors AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
),
ActorMovieCount AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM
        RecursiveMovieActors
    WHERE
        rn <= 5 
    GROUP BY
        actor_id, actor_name
),
TopActors AS (
    SELECT
        actor_id,
        actor_name,
        movie_count
    FROM
        ActorMovieCount
    ORDER BY
        movie_count DESC
    LIMIT 10
)
SELECT
    ta.actor_name,
    ta.movie_count,
    ARRAY_AGG(DISTINCT rm.title) AS recent_movies,
    ARRAY_AGG(DISTINCT rm.production_year) AS movie_years
FROM
    TopActors ta
JOIN
    RecursiveMovieActors rm ON ta.actor_id = rm.actor_id
GROUP BY
    ta.actor_id, ta.actor_name, ta.movie_count
ORDER BY
    ta.movie_count DESC;