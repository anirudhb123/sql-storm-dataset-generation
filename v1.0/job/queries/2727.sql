WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, a.name, r.role
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        co.country_code IS NOT NULL
),
MovieInfo AS (
    SELECT
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_details
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    ar.role_count,
    mc.company_name,
    mc.company_type,
    mi.movie_details
FROM
    RankedMovies rm
LEFT JOIN
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE
    (ar.role_count IS NULL OR ar.role_count > 1)
ORDER BY
    rm.production_year DESC, rm.title, ar.role_count DESC;
