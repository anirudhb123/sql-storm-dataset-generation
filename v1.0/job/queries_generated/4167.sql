WITH RecursiveMovieTitles AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
MovieRoles AS (
    SELECT
        c.movie_id,
        r.role_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        r.role IS NOT NULL
    GROUP BY
        c.movie_id, r.role_id
),
MovieCompanies AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY
        m.movie_id
),
TopMovies AS (
    SELECT
        mt.movie_id,
        mt.title,
        mt.production_year,
        m.actor_count,
        mc.company_count,
        (m.actor_count + COALESCE(mc.company_count, 0)) AS total_participants
    FROM
        RecursiveMovieTitles mt
    JOIN
        MovieRoles m ON mt.movie_id = m.movie_id
    LEFT JOIN
        MovieCompanies mc ON mt.movie_id = mc.movie_id
    WHERE
        mt.title_rank <= 10
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS actor_count,
    COALESCE(tm.company_count, 0) AS company_count,
    tm.total_participants
FROM
    TopMovies tm
ORDER BY
    tm.total_participants DESC,
    tm.production_year ASC;
