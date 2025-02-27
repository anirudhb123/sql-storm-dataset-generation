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

-- Bonus: Find movies with no cast information but are linked to other titles
WITH MoviesWithLinks AS (
    SELECT
        ml.movie_id,
        COUNT(DISTINCT ml.linked_movie_id) AS LinkedMoviesCount
    FROM
        movie_link ml
    WHERE
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'Remake')
    GROUP BY
        ml.movie_id
)
SELECT
    mt.title,
    COALESCE(mw.LinkedMoviesCount, 0) AS RemakeLinksCount
FROM
    aka_title mt
LEFT OUTER JOIN
    MoviesWithLinks mw ON mt.movie_id = mw.movie_id
WHERE
    NOT EXISTS (SELECT 1 FROM cast_info ci WHERE ci.movie_id = mt.movie_id)
ORDER BY
    mt.title;

-- Example of a correlated subquery using character manipulations and NULL checks
SELECT
    mt.title,
    UPPER(SUBSTRING(mt.title FROM 1 FOR 1)) || LOWER(SUBSTRING(mt.title FROM 2)) AS FormattedTitle,
    (SELECT COUNT(DISTINCT ci.person_id) FROM cast_info ci WHERE ci.movie_id = mt.movie_id AND ci.note IS NOT NULL) AS NonNullNotesCount
FROM
    aka_title mt
WHERE
    EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = mt.movie_id AND mi.info IS NULL)
    AND NOT EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = mt.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget'))
ORDER BY
    FormattedTitle;
