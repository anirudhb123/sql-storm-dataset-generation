WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title AS t
    JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),

TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        STRING_AGG(keyword, ', ') AS keywords
    FROM
        RankedMovies
    WHERE
        keyword_rank <= 5
    GROUP BY
        movie_id, title, production_year
),

CastInfo AS (
    SELECT
        c.movie_id,
        n.name,
        r.role,
        COUNT(c.person_id) AS cast_count
    FROM
        cast_info AS c
    JOIN
        aka_name AS n ON c.person_id = n.person_id
    JOIN
        role_type AS r ON c.role_id = r.id
    GROUP BY
        c.movie_id, n.name, r.role
)

SELECT
    tm.title,
    tm.production_year,
    tc.cast_count,
    tc.name AS lead_actor,
    tm.keywords
FROM
    TopMovies AS tm
LEFT JOIN
    CastInfo AS tc ON tm.movie_id = tc.movie_id
WHERE
    tc.cast_count > 1
ORDER BY
    tm.production_year DESC, tm.title;
