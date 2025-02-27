WITH MovieRoleCounts AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        COUNT(ci.id) AS role_count
    FROM
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE
        t.production_year > 2000
    GROUP BY
        a.name, t.title
),
TopMovies AS (
    SELECT
        movie_title,
        AVG(role_count) AS avg_roles
    FROM
        MovieRoleCounts
    GROUP BY
        movie_title
    HAVING
        COUNT(*) > 5
),
MostFrequentActors AS (
    SELECT
        actor_name,
        COUNT(*) AS movie_count
    FROM
        MovieRoleCounts
    GROUP BY
        actor_name
    ORDER BY
        movie_count DESC
    LIMIT 10
)
SELECT
    T.movie_title,
    T.avg_roles,
    A.actor_name,
    A.movie_count
FROM
    TopMovies T
JOIN MostFrequentActors A ON T.movie_title IN (
    SELECT movie_title FROM MovieRoleCounts WHERE actor_name = A.actor_name
)
ORDER BY
    T.avg_roles DESC, A.movie_count DESC;
