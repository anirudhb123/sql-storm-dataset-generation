WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.kind_id) AS total_movies
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS cast_count,
        COALESCE(NULLIF(c.note, ''), 'No Notes') AS role_notes
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        role_type r ON c.role_id = r.id
    WHERE
        c.note IS NOT NULL OR c.note IS NULL
),
MovieInfo AS (
    SELECT
        m.movie_id,
        STRING_AGG(i.info, ', ') AS info_details,
        MAX(i.note) AS note_details
    FROM
        movie_info m
    LEFT JOIN
        info_type it ON m.info_type_id = it.id
    GROUP BY
        m.movie_id
),
FilteredMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.actor_role,
        cd.role_notes,
        mi.info_details
    FROM
        RankedMovies rm
    JOIN
        CastDetails cd ON rm.title = cd.actor_role
    LEFT JOIN
        MovieInfo mi ON rm.production_year < 2000 AND cd.movie_id = mi.movie_id
    WHERE
        rm.year_rank <= 3
)
SELECT
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_name, 'Unknown Actor') AS actor_name,
    fm.actor_role,
    fm.role_notes,
    fm.info_details
FROM
    FilteredMovies fm
ORDER BY
    fm.production_year DESC,
    fm.actor_name ASC
LIMIT 25;
