WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
PopularActors AS (
    SELECT
        ca.movie_id,
        a.id AS actor_id,
        a.name,
        COUNT(ca.person_role_id) AS role_count
    FROM
        cast_info ca
    JOIN
        aka_name a ON ca.person_id = a.person_id
    GROUP BY
        ca.movie_id, a.id
    HAVING
        COUNT(ca.person_role_id) > 2
),
MovieCompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keyword,
    pa.actor_id,
    pa.name AS actor_name,
    pa.role_count,
    mcd.company_name,
    mcd.company_type
FROM
    RankedMovies rm
LEFT JOIN
    PopularActors pa ON rm.movie_id = pa.movie_id
LEFT JOIN
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
WHERE
    rm.rn = 1
ORDER BY
    rm.production_year DESC, pa.role_count DESC;
