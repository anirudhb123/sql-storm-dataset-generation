
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorsAndRoles AS (
    SELECT
        a.name,
        c.movie_id,
        c.nr_order,
        r.role
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
MovieGenres AS (
    SELECT
        m.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS genres
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
),
SelectedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mg.genres, 'Unknown') AS genres
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieGenres mg ON rm.movie_id = mg.movie_id
    WHERE
        rm.year_rank <= 5
)
SELECT
    sm.title,
    sm.production_year,
    sm.genres,
    LISTAGG(DISTINCT ar.name || ' (' || ar.role || ')', '; ') WITHIN GROUP (ORDER BY ar.name) AS actors
FROM
    SelectedMovies sm
LEFT JOIN
    ActorsAndRoles ar ON sm.movie_id = ar.movie_id
GROUP BY
    sm.movie_id, sm.title, sm.production_year, sm.genres
ORDER BY
    sm.production_year DESC, sm.title
LIMIT 10;
