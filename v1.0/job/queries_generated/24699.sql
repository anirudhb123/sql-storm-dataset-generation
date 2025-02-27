WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        at.kind_id,
        COUNT(ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_note_avg,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY
        at.title, at.production_year, at.kind_id
),
FilteredMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count,
        rm.has_note_avg
    FROM
        RankedMovies rm
    WHERE
        rm.cast_count > 5 AND rm.production_year >= 2000
),
NotableMovies AS (
    SELECT
        fm.title,
        fm.production_year,
        fm.kind_id,
        STRING_AGG(DISTINCT c.name, ', ') AS notable_cast
    FROM
        FilteredMovies fm
    INNER JOIN
        cast_info ci ON fm.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = ci.movie_id)
    INNER JOIN
        aka_name c ON ci.person_id = c.person_id
    GROUP BY
        fm.title, fm.production_year, fm.kind_id
)
SELECT
    nm.title,
    nm.production_year,
    km.keyword,
    nm.notable_cast
FROM
    NotableMovies nm
LEFT JOIN
    movie_keyword mk ON (SELECT m.movie_id FROM aka_title m WHERE m.title = nm.title) = mk.movie_id
LEFT JOIN
    keyword km ON mk.keyword_id = km.id
WHERE
    (km.keyword IS NOT NULL AND nm.production_year % 2 = 0)
    OR nm.notable_cast IS NULL
ORDER BY
    nm.production_year DESC, nm.title;
