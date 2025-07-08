
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM
        aka_title t
    JOIN
        cast_info c ON c.movie_id = t.id
    JOIN
        aka_name a ON a.person_id = c.person_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        total_cast,
        cast_names
    FROM
        RankedMovies
    WHERE
        rn <= 10
)
SELECT
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    mci.note AS company_note,
    mi.info AS movie_info,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM
    TopMovies tm
LEFT JOIN
    movie_companies mci ON mci.movie_id = tm.movie_id
LEFT JOIN
    movie_info mi ON mi.movie_id = tm.movie_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN
    keyword kw ON kw.id = mk.keyword_id
GROUP BY
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    mci.note,
    mi.info
ORDER BY
    tm.production_year DESC, tm.total_cast DESC;
