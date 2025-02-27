WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        t.imdb_index,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        tp.kind AS title_kind
    FROM
        title t
    JOIN
        aka_title at ON t.id = at.movie_id
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword kw ON mk.keyword_id = kw.id
    JOIN
        kind_type tp ON t.kind_id = tp.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year, t.imdb_index, tp.kind
),
TopMovies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rn
    FROM
        RankedMovies
)
SELECT
    movie.title,
    movie.production_year,
    movie.total_cast,
    movie.cast_names,
    movie.keywords,
    movie.title_kind
FROM
    TopMovies movie
WHERE
    movie.rn <= 10
ORDER BY
    movie.total_cast DESC;
