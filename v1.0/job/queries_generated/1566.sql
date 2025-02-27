WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank_year
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM
        RankedMovies rm
    WHERE
        rm.rank_year <= 5
),
CastRoles AS (
    SELECT
        ci.movie_id,
        ci.person_role_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id, ci.person_role_id
),
MovieAwards AS (
    SELECT
        m.movie_id,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS award_count
    FROM
        movie_info mi
    JOIN
        TopMovies tm ON mi.movie_id = tm.movie_id
    GROUP BY
        m.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    cr.actor_count,
    COALESCE(ma.award_count, 0) AS award_count
FROM
    TopMovies tm
LEFT JOIN
    CastRoles cr ON tm.movie_id = cr.movie_id
LEFT JOIN
    MovieAwards ma ON tm.movie_id = ma.movie_id
ORDER BY
    tm.production_year DESC, award_count DESC, actor_count DESC;
