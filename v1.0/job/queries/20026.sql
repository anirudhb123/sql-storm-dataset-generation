WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    WHERE
        t.production_year IS NOT NULL
    AND
        t.title IS NOT NULL
),
CastSummary AS (
    SELECT
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT a.id) AS unique_actors
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
MoviesWithDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.cast_names,
        cs.unique_actors,
        CASE WHEN cs.unique_actors > 10 THEN 'Ensemble' ELSE 'Small Cast' END AS cast_size
    FROM
        RankedMovies rm
    LEFT JOIN
        CastSummary cs ON rm.movie_id = cs.movie_id
)
SELECT
    m.title,
    m.production_year,
    m.cast_names,
    m.unique_actors,
    m.cast_size,
    CASE 
        WHEN m.cast_size = 'Ensemble' THEN 'This movie features a large ensemble cast!'
        ELSE 'This movie features a smaller cast.'
    END AS cast_description
FROM
    MoviesWithDetails m
WHERE
    m.production_year >= 2000
ORDER BY
    m.production_year DESC,
    m.unique_actors DESC
LIMIT 100;