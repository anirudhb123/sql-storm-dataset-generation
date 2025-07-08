WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        k.keyword,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year >= 2000
),
ActorCount AS (
    SELECT
        production_year,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM
        RankedMovies
    GROUP BY
        production_year
),
TopMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.actor_name,
        ac.actor_count
    FROM
        RankedMovies rm
    JOIN
        ActorCount ac ON rm.production_year = ac.production_year
    WHERE
        rm.actor_rank <= 3
)
SELECT
    production_year,
    ARRAY_AGG(title) AS top_movies,
    SUM(actor_count) AS total_actors
FROM
    TopMovies
GROUP BY
    production_year
ORDER BY
    production_year DESC;
