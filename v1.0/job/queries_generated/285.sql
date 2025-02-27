WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastMovies AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        cm.actor_count,
        COALESCE(MIN(ki.id), 0) AS min_keyword_id
    FROM
        RankedMovies rm
    LEFT JOIN
        CastMovies cm ON rm.movie_id = cm.movie_id
    LEFT JOIN
        movie_keyword ki ON rm.movie_id = ki.movie_id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year, cm.actor_count
),
MovieInfo AS (
    SELECT
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.actor_count,
        CASE 
            WHEN fm.actor_count IS NULL THEN 'No Actors'
            ELSE 'Actors Present'
        END AS actor_status
    FROM
        FilteredMovies fm
    WHERE
        fm.production_year > 2000
)
SELECT
    mi.title,
    mi.production_year,
    mi.actor_count,
    mi.actor_status,
    (SELECT COUNT(DISTINCT mc.company_id)
     FROM movie_companies mc
     WHERE mc.movie_id = mi.movie_id) AS company_count
FROM
    MovieInfo mi
WHERE
    mi.actor_count > 1
ORDER BY
    mi.production_year DESC, mi.title ASC;
