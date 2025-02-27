WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year IS NOT NULL
),
DirectorCount AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS director_count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    WHERE
        rt.role = 'director'
    GROUP BY
        ci.movie_id
),
MoviesWithDirectors AS (
    SELECT
        rm.*,
        dc.director_count
    FROM
        RankedMovies rm
    LEFT JOIN
        DirectorCount dc ON rm.title_id = dc.movie_id
)
SELECT
    m.title,
    m.production_year,
    COALESCE(m.director_count, 0) AS director_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM
    MoviesWithDirectors m
LEFT JOIN
    movie_keyword mk ON m.title_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    (m.production_year IS NOT NULL AND m.rank_year <= 5) OR
    (m.director_count IS NULL)
GROUP BY
    m.title_id, m.title, m.production_year, m.director_count
HAVING
    COUNT(DISTINCT k.keyword) > 1
ORDER BY
    m.production_year DESC, m.title;
