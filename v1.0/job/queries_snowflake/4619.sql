
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(c.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    WHERE
        a.production_year IS NOT NULL
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        year_rank <= 5
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
),
MoviesWithKeywords AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM
        TopMovies tm
    LEFT JOIN
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.keywords,
    CAST(COALESCE(NULLIF(mw.keywords, 'No keywords'), '') AS STRING) AS keyword_check
FROM
    MoviesWithKeywords mw
WHERE
    mw.production_year >= (SELECT MAX(production_year) FROM aka_title) - 10
ORDER BY
    mw.production_year DESC,
    mw.movie_id;
