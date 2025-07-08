
WITH RankedMovies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rn <= 5
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, '; ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cm.companies, 'No Companies') AS companies,
    CASE
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM
    TopMovies tm
LEFT JOIN
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN
    CompanyMovies cm ON tm.movie_id = cm.movie_id
ORDER BY
    tm.production_year DESC,
    tm.title ASC;
