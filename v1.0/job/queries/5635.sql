
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.id
    GROUP BY
        t.title, t.production_year, t.kind_id
),
HighCastMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count,
        kt.kind
    FROM
        RankedMovies rm
    JOIN
        kind_type kt ON rm.kind_id = kt.id
    WHERE
        rm.cast_count > 10
),
DetailedMovieInfo AS (
    SELECT
        hcm.title,
        hcm.production_year,
        hcm.cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT pi.info, ', ') AS person_infos
    FROM
        HighCastMovies hcm
    LEFT JOIN
        movie_companies mc ON hcm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        movie_keyword mk ON hcm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        person_info pi ON pi.person_id IN (
            SELECT DISTINCT c.person_id
            FROM cast_info c
            JOIN complete_cast cc ON c.movie_id = cc.movie_id
            WHERE cc.subject_id IN (
                SELECT id FROM aka_name WHERE md5sum IS NOT NULL
            )
        )
    GROUP BY
        hcm.title, hcm.production_year, hcm.cast_count
)
SELECT
    dmi.title,
    dmi.production_year,
    dmi.cast_count,
    dmi.company_names,
    dmi.keywords,
    dmi.person_infos
FROM
    DetailedMovieInfo dmi
ORDER BY
    dmi.production_year DESC, dmi.cast_count DESC;
