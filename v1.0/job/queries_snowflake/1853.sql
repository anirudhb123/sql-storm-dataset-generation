
WITH RankedMovies AS (
    SELECT
        a.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank,
        COALESCE(SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS notable_cast_count
    FROM
        aka_title a
    JOIN
        title t ON a.movie_id = t.id
    JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        a.title,
        t.production_year
),
RecentMovies AS (
    SELECT
        title,
        production_year,
        notable_cast_count
    FROM
        RankedMovies
    WHERE
        production_year >= (SELECT MAX(production_year) FROM title) - 10
),
CompanyParticipation AS (
    SELECT
        m.movie_id,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies_involved
    FROM
        movie_companies m
    JOIN
        company_name c ON m.company_id = c.id
    GROUP BY
        m.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    rm.notable_cast_count,
    cp.companies_involved
FROM
    RecentMovies rm
LEFT JOIN
    CompanyParticipation cp ON rm.production_year = (SELECT MAX(production_year) FROM title)
WHERE
    rm.notable_cast_count > 0
ORDER BY
    rm.production_year DESC,
    rm.notable_cast_count DESC;
