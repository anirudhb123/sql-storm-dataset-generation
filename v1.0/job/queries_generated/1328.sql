WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year,
        cast_count
    FROM
        RankedMovies
    WHERE
        year_rank <= 5
),
CompanyInfo AS (
    SELECT
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.company_id) AS total_companies
    FROM
        movie_companies m
    JOIN
        company_name co ON m.company_id = co.id
    JOIN
        company_type ct ON m.company_type_id = ct.id
    GROUP BY
        m.movie_id, co.name, ct.kind
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    ci.company_name,
    ci.company_type,
    ci.total_companies
FROM
    TopMovies tm
LEFT JOIN
    CompanyInfo ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
ORDER BY
    tm.production_year DESC, tm.cast_count DESC
LIMIT 10;
