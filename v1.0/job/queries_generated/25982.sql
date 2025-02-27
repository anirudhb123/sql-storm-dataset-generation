WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title AS m
    LEFT JOIN
        cast_info AS c ON m.id = c.movie_id
    LEFT JOIN
        aka_name AS ak ON c.person_id = ak.person_id
    LEFT JOIN
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    tm.keywords
FROM
    TopMovies AS tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;

This SQL query utilizes Common Table Expressions (CTEs) to rank movies based on the number of unique actors (cast count) from the `aka_title`, `cast_info`, and `aka_name` tables, while also aggregating a list of distinct actors and keywords associated with each movie. It filters for movies released between 2000 and 2023, selects the top 10 movies by cast size, and orders them by production year descending for an intriguing benchmarking of string processing capabilities in SQL.
