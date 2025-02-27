WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = mt.id
    WHERE
        mt.production_year IS NOT NULL
    GROUP BY
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
MovieCast AS (
    SELECT
        tc.movie_id,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        COUNT(DISTINCT ac.person_id) AS cast_count
    FROM
        complete_cast tc
    JOIN
        aka_name ak ON ak.person_id = tc.subject_id
    JOIN
        cast_info ac ON ac.movie_id = tc.movie_id
    GROUP BY
        tc.movie_id
),
MovieDetails AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        mc.actors,
        mc.cast_count
    FROM
        TopMovies tm
    LEFT JOIN
        MovieCast mc ON mc.movie_id = tm.movie_id
)
SELECT
    md.title,
    md.production_year,
    md.cast_count,
    md.actors
FROM
    MovieDetails md
ORDER BY
    md.production_year DESC, md.cast_count DESC;
