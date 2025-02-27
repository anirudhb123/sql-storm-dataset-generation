WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title a
    JOIN
        complete_cast cc ON a.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.id
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    WHERE
        a.production_year >= 2000
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    tm.keywords
FROM
    TopMovies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.cast_count DESC;
