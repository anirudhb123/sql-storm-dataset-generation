
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id, title, production_year, cast_count, null_notes_count
    FROM
        RankedMovies
    WHERE
        rn <= 10
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
FinalResults AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        CASE 
            WHEN tm.null_notes_count > 0 THEN 'Contains NULL notes'
            ELSE 'No NULL notes'
        END AS notes_status,
        mk.keywords
    FROM
        TopMovies tm
    LEFT JOIN
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.notes_status,
    COALESCE(fr.keywords, 'No keywords') AS keywords
FROM
    FinalResults fr
ORDER BY
    fr.production_year DESC, fr.cast_count DESC;
