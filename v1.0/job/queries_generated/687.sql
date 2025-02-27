WITH MovieRoles AS (
    SELECT
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, r.role
),
TopMovies AS (
    SELECT
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM
        aka_title m
    JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.title, m.production_year
),
MoviesWithKeywords AS (
    SELECT
        m.title,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.title, k.keyword
),
FinalMovies AS (
    SELECT
        tm.production_year,
        tm.title,
        COALESCE(mr.role, 'No Role') AS role,
        COALESCE(mwk.keyword, 'No Keyword') AS keyword,
        COALESCE(mr.role_count, 0) AS total_roles,
        COALESCE(mwk.keyword_count, 0) AS total_keywords
    FROM
        TopMovies tm
    LEFT JOIN
        MovieRoles mr ON tm.movie_id = mr.movie_id
    LEFT JOIN
        MoviesWithKeywords mwk ON tm.title = mwk.title
    WHERE
        tm.rank <= 5
)
SELECT
    f.production_year,
    f.title,
    f.role,
    f.keyword,
    f.total_roles,
    f.total_keywords
FROM
    FinalMovies f
WHERE
    f.total_keywords > 0 OR f.total_roles > 0
ORDER BY
    f.production_year DESC, f.title;
