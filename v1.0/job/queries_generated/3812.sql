WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    GROUP BY
        t.id, t.title, t.production_year
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
KeywordStats AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        TopMovies m ON mk.movie_id = m.movie_id
    GROUP BY
        m.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    COALESCE(c.cast_count, 0) AS total_cast
FROM
    TopMovies t
LEFT JOIN
    KeywordStats k ON t.movie_id = k.movie_id
LEFT JOIN (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id
) c ON t.movie_id = c.movie_id
ORDER BY
    t.production_year DESC, t.title;
