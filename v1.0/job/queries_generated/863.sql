WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(mk.keyword IS NOT NULL), 0) AS keyword_count,
        COALESCE(SUM(pi.info IS NOT NULL), 0) AS person_info_count
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN
        person_info pi ON cc.subject_id = pi.person_id
    WHERE
        rm.rank_by_cast <= 5
    GROUP BY
        rm.movie_id, rm.title, rm.production_year
),
FinalResult AS (
    SELECT
        tm.title,
        tm.production_year,
        tm.keyword_count,
        tm.person_info_count,
        CASE
            WHEN tm.keyword_count > 0 THEN 'Has Keywords'
            ELSE 'No Keywords'
        END AS keyword_status,
        CASE
            WHEN tm.person_info_count > 0 THEN 'Has Person Info'
            ELSE 'No Person Info'
        END AS person_info_status
    FROM
        TopMovies tm
)

SELECT
    fr.title,
    fr.production_year,
    fr.keyword_count,
    fr.person_info_count,
    fr.keyword_status,
    fr.person_info_status
FROM
    FinalResult fr
WHERE
    fr.keyword_count > 2
ORDER BY
    fr.production_year DESC, fr.keyword_count DESC;
