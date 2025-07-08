
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM
        aka_title m
    JOIN
        cast_info c ON m.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        total_cast,
        cast_names,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM
        RankedMovies
    WHERE
        total_cast > 5
)
SELECT
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    k.keyword AS related_keyword,
    ct.kind AS company_type
FROM
    TopMovies tm
LEFT JOIN
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
WHERE
    tm.rank <= 10
ORDER BY
    tm.total_cast DESC, tm.movie_title;
