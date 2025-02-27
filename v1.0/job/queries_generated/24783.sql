WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id,
        a.title,
        a.production_year
),
FilteredMovies AS (
    SELECT
        *,
        CASE
            WHEN cast_count IS NULL THEN 'No Cast'
            WHEN cast_count = 0 THEN 'Empty Cast'
            ELSE 'Has Cast'
        END AS cast_status
    FROM
        RankedMovies
    WHERE
        production_year BETWEEN 2000 AND 2023
),
MaxCastMovies AS (
    SELECT
        title,
        production_year,
        cast_count,
        cast_status
    FROM
        FilteredMovies
    WHERE
        rank_by_cast = 1
)
SELECT
    m.title,
    m.production_year,
    m.cast_count,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COALESCE(cn.name, 'Unknown Company') AS company_name
FROM
    MaxCastMovies m
LEFT JOIN
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
WHERE
    (m.cast_count > 5 OR m.cast_status = 'No Cast')
AND
    (EXTRACT(YEAR FROM NOW()) - m.production_year) < 5
ORDER BY
    m.production_year DESC,
    m.cast_count ASC
LIMIT 10;

-- Follow-up check for movies with intriguing semantic anomalies
SELECT
    DISTINCT m.title,
    COALESCE((
        SELECT STRING_AGG(xt.link, ', ')
        FROM (
            SELECT l.link AS link
            FROM movie_link l
            WHERE l.movie_id = m.movie_id
            AND (m.cast_status = 'Has Cast' OR m.cast_status = 'No Cast')
        ) AS xt
    ), 'No Links') AS related_links
FROM
    MaxCastMovies m
WHERE
    m.production_year IS NOT NULL
    AND (m.cast_count < ALL (SELECT cast_count FROM MaxCastMovies))
ORDER BY
    m.production_year DESC;
