WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info ci ON a.id = ci.movie_id
    GROUP BY
        a.title, a.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year,
        actor_count
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, c.name, ct.kind
)
SELECT
    tm.title,
    tm.production_year,
    tm.actor_count,
    STRING_AGG(CONCAT(cm.company_name, ' (', cm.company_type, ')'), '; ') AS companies
FROM
    TopMovies tm
LEFT JOIN
    CompanyMovies cm ON tm.actor_count = cm.company_count
GROUP BY
    tm.title, tm.production_year, tm.actor_count
HAVING
    COUNT(cm.company_name) > 0 OR SUM(cm.company_count) IS NULL 
ORDER BY
    tm.production_year DESC, tm.actor_count DESC;
