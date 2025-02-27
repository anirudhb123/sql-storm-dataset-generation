WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM
        title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        aka_title ak ON m.id = ak.movie_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        aliases,
        keywords
    FROM
        RankedMovies
    WHERE
        rank <= 5
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aliases,
    ARRAY_LENGTH(tm.keywords, 1) AS keyword_count,
    COALESCE(COUNT(DISTINCT c.role_id), 0) AS unique_roles,
    STRING_AGG(DISTINCT rt.role, ', ') AS roles
FROM
    TopMovies tm
LEFT JOIN
    cast_info c ON tm.movie_id = c.movie_id
LEFT JOIN
    role_type rt ON c.role_id = rt.id
GROUP BY
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.aliases
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
