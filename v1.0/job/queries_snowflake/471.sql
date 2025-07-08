
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year,
        cast_count
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
MovieCompaniesInfo AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mci.companies, 'No Companies') AS companies,
    COALESCE(mci.company_types, 'No Types') AS company_types
FROM
    TopMovies tm
LEFT JOIN
    MovieCompaniesInfo mci ON tm.title = (SELECT title FROM aka_title WHERE id = mci.movie_id)
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
