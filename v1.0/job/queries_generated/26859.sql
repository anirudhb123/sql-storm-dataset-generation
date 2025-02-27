WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names
    FROM
        RankedMovies rm
    WHERE
        rm.production_year BETWEEN 2000 AND 2023
        AND rm.cast_count > 5
        AND rm.title ILIKE '%action%'
),
MovieNotes AS (
    SELECT
        fm.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_info
    FROM
        FilteredMovies fm
    JOIN
        movie_info mi ON fm.movie_id = mi.movie_id
    GROUP BY
        fm.movie_id
)
SELECT
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.actor_names,
    COALESCE(mn.movie_info, 'No additional info') AS additional_info
FROM
    FilteredMovies fm
LEFT JOIN
    MovieNotes mn ON fm.movie_id = mn.movie_id
ORDER BY
    fm.production_year DESC, fm.cast_count DESC;
