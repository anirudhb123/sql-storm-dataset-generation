WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
CompanyDetails AS (
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
),
MoviesWithDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.role_name,
        co.company_name,
        co.company_type
    FROM
        RankedMovies rm
    LEFT JOIN
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN
        CompanyDetails co ON rm.movie_id = co.movie_id
)
SELECT
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actor_names,
    STRING_AGG(DISTINCT role_name, ', ') AS roles,
    STRING_AGG(DISTINCT CONCAT(company_name, ' (', company_type, ')'), ', ') AS companies
FROM
    MoviesWithDetails
GROUP BY
    title, production_year
ORDER BY
    production_year DESC, title;
