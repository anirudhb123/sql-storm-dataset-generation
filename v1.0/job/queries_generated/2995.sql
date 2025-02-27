WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
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
    ci.companies,
    ci.company_types,
    (SELECT COUNT(*) FROM cast_info ci2 WHERE ci2.movie_id = tm.movie_id AND ci2.note IS NOT NULL) AS total_cast_with_notes,
    (SELECT AVG(CASE WHEN mi.info_type_id = it.id THEN LENGTH(mi.info) END)
     FROM movie_info mi
     JOIN info_type it ON mi.info_type_id = it.id
     WHERE mi.movie_id = tm.movie_id) AS avg_info_length
FROM
    TopMovies tm
LEFT JOIN
    CompanyInfo ci ON tm.movie_id = ci.movie_id
ORDER BY
    tm.production_year DESC, tm.title;
