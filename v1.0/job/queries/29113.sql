WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM
        aka_title at
    JOIN
        movie_keyword mk ON at.id = mk.movie_id
    JOIN
        aka_name ak ON mk.keyword_id = ak.id
    WHERE
        at.production_year >= 2000
        AND ak.name IS NOT NULL
),

FilteredActors AS (
    SELECT
        rm.actor_name,
        COUNT(DISTINCT rm.title) AS total_movies
    FROM
        RankedMovies rm
    WHERE
        rm.year_rank <= 5
    GROUP BY
        rm.actor_name
),

TopActors AS (
    SELECT
        actor_name,
        total_movies,
        RANK() OVER (ORDER BY total_movies DESC) AS actor_rank
    FROM
        FilteredActors
)

SELECT
    ta.actor_name,
    ta.total_movies
FROM
    TopActors ta
WHERE
    ta.actor_rank <= 10
ORDER BY
    ta.total_movies DESC;
