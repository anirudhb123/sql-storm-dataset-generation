WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),

CastDetails AS (
    SELECT
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(a.name, ', ') AS actors
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),

MovieInfo AS (
    SELECT
        m.id,
        m.title,
        m.production_year,
        ci.cast_count,
        ci.actors,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) as recent_rank
    FROM
        title m
    JOIN CastDetails ci ON m.id = ci.movie_id
)

SELECT
    rm.year_rank,
    mi.id AS movie_id,
    mi.title,
    mi.production_year,
    mi.cast_count,
    mi.actors,
    COALESCE(ci.info, 'No additional info') AS additional_info
FROM
    RankedMovies rm
JOIN MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN movie_info ci ON mi.movie_id = ci.movie_id
WHERE
    rm.year_rank <= 10
    AND mi.recent_rank <= 20
ORDER BY
    mi.production_year DESC,
    rm.year_rank;

This SQL query benchmarks string processing by utilizing Common Table Expressions (CTEs) to create ranks based on production year and aggregate cast details for movies, providing a structured overview of the top 10 movies per production year, while showing additional information where available.
