WITH RankedMovies AS (
    SELECT
        mt.title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS RankByYear,
        STRING_AGG(aka.name, ', ') AS ActorNames
    FROM
        aka_title mt
    JOIN
        cast_info ci ON ci.movie_id = mt.movie_id
    JOIN
        aka_name aka ON aka.person_id = ci.person_id
    GROUP BY
        mt.id, mt.title, mt.production_year, mt.kind_id
), FilteredMovies AS (
    SELECT
        *,
        CASE
            WHEN production_year > 2000 THEN 'Modern'
            WHEN production_year < 1960 THEN 'Classic'
            ELSE 'Contemporary'
        END AS Era
    FROM
        RankedMovies
    WHERE
        ActorNames IS NOT NULL
)
SELECT
    fm.title,
    fm.production_year,
    fm.Era,
    COUNT(*) FILTER (WHERE ci.role_id IS NOT NULL) AS TotalCastRole,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS NotesProvided
FROM
    FilteredMovies fm
LEFT JOIN
    cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)
WHERE
    fm.RankByYear <= 5
GROUP BY
    fm.title, fm.production_year, fm.Era
HAVING
    COUNT(ci.role_id) < (SELECT COUNT(*) FROM cast_info WHERE role_id IS NOT NULL) / 10
ORDER BY
    fm.production_year DESC, fm.title;