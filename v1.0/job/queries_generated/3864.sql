WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS non_empty_notes,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    WHERE
        a.production_year > 2000
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year,
        total_cast,
        non_empty_notes
    FROM
        RankedMovies
    WHERE
        rank <= 10
),
DirectorMovies AS (
    SELECT
        m.title,
        m.production_year,
        d.name AS director_name
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name d ON mc.company_id = d.id
    WHERE
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
)
SELECT
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.non_empty_notes,
    COALESCE(dm.director_name, 'Unknown') AS director_name
FROM
    TopMovies tm
LEFT JOIN
    DirectorMovies dm ON tm.title = dm.title AND tm.production_year = dm.production_year
UNION ALL
SELECT
    DISTINCT a.title,
    a.production_year,
    0 AS total_cast,
    0 AS non_empty_notes,
    COALESCE(dm.director_name, 'Unknown') AS director_name
FROM
    aka_title a
LEFT JOIN
    DirectorMovies dm ON a.title = dm.title
WHERE
    a.production_year <= 2000 AND a.title NOT IN (SELECT title FROM TopMovies)
ORDER BY
    production_year DESC, total_cast DESC;
