WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
MovieGenre AS (
    SELECT
        m.id AS movie_id,
        k.keyword AS genre
    FROM
        aka_title m
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword IS NOT NULL
),
FinalBenchmark AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        STRING_AGG(DISTINCT mg.genre, ', ') AS genres,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC, rm.production_year DESC) AS ranking
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieGenre mg ON rm.movie_id = mg.movie_id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year, rm.cast_count
)
SELECT
    movie_id,
    title,
    production_year,
    cast_count,
    genres,
    ranking
FROM
    FinalBenchmark
WHERE
    ranking <= 10
ORDER BY
    ranking;
