WITH MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM
        title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        md.title,
        md.production_year,
        md.actor_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS actor_rank
    FROM
        MovieDetails md
)
SELECT
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(cin.info, 'No info available') AS additional_info
FROM
    TopMovies tm
LEFT JOIN
    movie_info mi ON tm.title = (SELECT DISTINCT title FROM title WHERE id IN (SELECT movie_id FROM movie_info WHERE info_type_id = 1)) AND mi.movie_id = (SELECT DISTINCT id FROM title WHERE title = tm.title)
LEFT JOIN
    movie_info_idx cin ON cin.movie_id = (SELECT id FROM title WHERE title = tm.title LIMIT 1)
WHERE
    tm.actor_count > 5
    AND tm.actor_rank <= 10
ORDER BY
    tm.production_year DESC,
    tm.actor_count DESC;
