WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM
        aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN cast_info cc ON mt.id = cc.movie_id
    GROUP BY
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        rm.keyword_count,
        rm.cast_count,
        COALESCE(ci.note, 'No Comments') AS cast_note,
        (SELECT COUNT(*) FROM complete_cast WHERE movie_id = rm.movie_id) AS complete_cast_count
    FROM
        RankedMovies rm
    LEFT JOIN complete_cast ci ON rm.movie_id = ci.movie_id
    WHERE
        rm.year_rank <= 3
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
FinalReport AS (
    SELECT
        tm.title,
        tm.production_year,
        tm.keyword_count,
        tm.cast_count,
        mc.company_names,
        tm.complete_cast_count,
        CASE
            WHEN mc.company_count IS NULL THEN 'No Companies Listed'
            ELSE CONCAT(mc.company_count::text, ' Companies')
        END AS company_info,
        CASE 
            WHEN tm.complete_cast_count = 0 THEN 'Unfinished'
            ELSE 'Completed'
        END AS cast_status
    FROM
        TopMovies tm
    LEFT JOIN MovieCompanies mc ON tm.movie_id = mc.movie_id
)
SELECT
    fr.title,
    fr.production_year,
    fr.keyword_count,
    fr.cast_count,
    fr.company_names,
    fr.company_info,
    fr.cast_status
FROM
    FinalReport fr
ORDER BY
    fr.production_year DESC,
    fr.keyword_count DESC
LIMIT 10;
