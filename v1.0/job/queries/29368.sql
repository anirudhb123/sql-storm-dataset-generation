WITH RankedMovies AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.name ASC) AS actor_rank
    FROM
        aka_title a
    JOIN
        cast_info ci ON a.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        a.production_year >= 2000
),
MovieStatistics AS (
    SELECT
        movie_title,
        production_year,
        COUNT(actor_name) AS total_actors,
        STRING_AGG(actor_name, ', ') AS actor_list
    FROM
        RankedMovies
    GROUP BY
        movie_title, production_year
),
TopMovies AS (
    SELECT
        movie_title,
        production_year,
        total_actors,
        actor_list,
        RANK() OVER (ORDER BY total_actors DESC) AS movie_rank
    FROM
        MovieStatistics
)
SELECT
    movie_title,
    production_year,
    total_actors,
    actor_list
FROM
    TopMovies
WHERE
    movie_rank <= 10
ORDER BY
    production_year DESC;
