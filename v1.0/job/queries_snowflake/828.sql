
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        a.name NOT LIKE '%Unknown%'
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        am.actor_name,
        am.actor_count
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorMovies am ON rm.movie_id = am.movie_id
    WHERE
        rm.year_rank <= 5
)
SELECT
    fm.title,
    COALESCE(fm.actor_name, 'No Actor') AS actor_name,
    fm.production_year,
    CASE 
        WHEN fm.actor_count IS NULL THEN 'No Actor'
        ELSE CAST(fm.actor_count AS VARCHAR)
    END AS actor_count,
    LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM
    FilteredMovies fm
LEFT JOIN
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
GROUP BY
    fm.title,
    fm.production_year,
    fm.actor_name,
    fm.actor_count
ORDER BY
    fm.production_year DESC, fm.title;
