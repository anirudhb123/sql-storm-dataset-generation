WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title t
    JOIN
        complete_cast c ON t.id = c.movie_id
    JOIN
        cast_info ci ON c.subject_id = ci.person_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT
        rm.*,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM
        RankedMovies rm
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types
FROM
    TopMovies tm
JOIN
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN
    company_type c ON mc.company_type_id = c.id
WHERE
    tm.rank <= 10
GROUP BY
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.cast_names
ORDER BY
    tm.cast_count DESC;
