
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM
        aka_title a
    WHERE
        a.production_year IS NOT NULL
),
MovieCast AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM
        complete_cast mc
    JOIN
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        mc.movie_id
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(m.total_cast, 0) AS total_cast,
        m.cast_names 
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieCast m ON rm.movie_id = m.movie_id
    WHERE
        rm.rank <= 5
)
SELECT
    f.title,
    f.production_year,
    f.total_cast,
    STRING_AGG(DISTINCT mt.linked_movie_id::TEXT, ', ') AS linked_movies
FROM
    FilteredMovies f
LEFT JOIN
    movie_link mt ON f.movie_id = mt.movie_id
GROUP BY
    f.title, f.production_year, f.total_cast
HAVING
    (f.total_cast > 0 OR f.production_year IS NULL)
ORDER BY
    f.production_year DESC, f.title ASC;
