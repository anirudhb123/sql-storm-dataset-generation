WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000
),
MovieRoles AS (
    SELECT
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, r.role
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, co.name, ct.kind
),
CombinedInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mr.role, 'Unknown') AS role,
        mr.role_count,
        COALESCE(cd.company_name, 'Independent') AS company_name,
        COALESCE(cd.company_type, 'N/A') AS company_type,
        cd.company_count
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieRoles mr ON rm.movie_id = mr.movie_id
    LEFT JOIN
        CompanyDetails cd ON rm.movie_id = cd.movie_id
)
SELECT
    ci.title,
    ci.production_year,
    ci.role,
    ci.role_count,
    ci.company_name,
    ci.company_type,
    ci.company_count
FROM
    CombinedInfo ci
WHERE
    ci.production_year = (
        SELECT MAX(production_year)
        FROM RankedMovies
    )
ORDER BY
    ci.role_count DESC,
    ci.title ASC;
