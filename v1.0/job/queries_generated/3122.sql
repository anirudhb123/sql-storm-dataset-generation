WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_info
    FROM
        movie_info m
    JOIN
        movie_info_idx idx ON m.movie_id = idx.movie_id
    WHERE
        idx.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%rating%')
    GROUP BY
        m.movie_id
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS role_count
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.movie_id, r.role
),
FinalResult AS (
    SELECT
        rm.rank,
        rm.title,
        rm.production_year,
        COALESCE(mi.movie_info, 'No Info') AS additional_info,
        SUM(ar.role_count) AS total_roles
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieInfo mi ON rm.movie_id = mi.movie_id
    LEFT JOIN
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE
        rm.rank <= 5
    GROUP BY
        rm.rank, rm.title, rm.production_year, mi.movie_info
)
SELECT
    *,
    CASE
        WHEN total_roles IS NULL THEN 'No Roles'
        ELSE CAST(total_roles AS VARCHAR)
    END AS role_summary
FROM
    FinalResult
ORDER BY
    rank;
