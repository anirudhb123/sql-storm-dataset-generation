WITH YearlyMovies AS (
    SELECT
        production_year,
        COUNT(DISTINCT movie_id) AS movie_count,
        SUM(CASE WHEN note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM
        aka_title
    LEFT JOIN
        movie_info ON aka_title.movie_id = movie_info.movie_id
    GROUP BY
        production_year
),
TopDirectors AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS directed_movies
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    WHERE
        c.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY
        a.person_id, a.name
    HAVING
        COUNT(DISTINCT c.movie_id) > 5
),
FinalStats AS (
    SELECT
        ym.production_year,
        ym.movie_count,
        ym.notes_count,
        td.name AS top_director,
        td.directed_movies
    FROM
        YearlyMovies ym
    LEFT JOIN
        TopDirectors td ON ym.production_year = EXTRACT(YEAR FROM c.production_year)
    ORDER BY
        ym.production_year DESC
)
SELECT
    production_year,
    movie_count,
    notes_count,
    COALESCE(top_director, 'No Director') AS top_director,
    COALESCE(directed_movies, 0) AS directed_movies
FROM
    FinalStats
WHERE
    movie_count > 10
UNION ALL
SELECT
    production_year,
    movie_count,
    notes_count,
    'Unassigned' AS top_director,
    0 AS directed_movies
FROM
    YearlyMovies
WHERE
    production_year NOT IN (SELECT DISTINCT production_year FROM FinalStats)
ORDER BY
    production_year DESC;
