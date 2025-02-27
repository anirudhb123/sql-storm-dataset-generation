WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.person_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id
),
TopMovies AS (
    SELECT
        title,
        production_year,
        cast_count,
        actor_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
    WHERE
        cast_count >= 5
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names,
    k.keyword AS movie_keyword
FROM
    TopMovies tm
LEFT JOIN
    movie_keyword mk ON tm.title = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    tm.rank <= 10
ORDER BY
    tm.cast_count DESC,
    tm.title ASC;
