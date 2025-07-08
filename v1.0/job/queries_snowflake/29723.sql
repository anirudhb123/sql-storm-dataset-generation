
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        aka_title m
    JOIN
        cast_info c ON m.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id,
        m.title,
        m.production_year
),
TopMovies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)

SELECT
    t.movie_id,
    t.title,
    t.production_year,
    t.cast_count,
    t.actors,
    t.keywords
FROM
    TopMovies t
WHERE
    t.rank <= 10
ORDER BY
    t.cast_count DESC;
