WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.num_cast_members
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 3
),
CompanyData AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
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
    tm.num_cast_members,
    COALESCE(cd.companies, 'No Companies') AS companies_involved,
    (SELECT COUNT(DISTINCT ki.keyword)
     FROM movie_keyword mk
     JOIN keyword ki ON mk.keyword_id = ki.id
     WHERE mk.movie_id = tm.movie_id) AS keyword_count,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id = tm.movie_id 
       AND ci.note IS NULL) AS null_notes_count, /* Count of cast with no notes */
    (SELECT STRING_AGG(DISTINCT pi.info, '; ')
     FROM person_info pi
     JOIN cast_info ci ON pi.person_id = ci.person_id
     WHERE ci.movie_id = tm.movie_id
       AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')) AS biographied_cast
FROM
    TopMovies tm
LEFT JOIN
    CompanyData cd ON tm.movie_id = cd.movie_id
ORDER BY
    tm.production_year DESC, 
    tm.num_cast_members DESC;