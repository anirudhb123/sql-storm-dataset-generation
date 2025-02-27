WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    *,
    (CASE
        WHEN production_year >= 2020 THEN 'Recent'
        WHEN production_year >= 2010 THEN 'Last Decade'
        ELSE 'Older'
    END) AS age_category
FROM
    TopMovies
WHERE
    rank <= 10
ORDER BY
    cast_count DESC;
