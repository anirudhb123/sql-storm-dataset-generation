WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
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
        COUNT(*) AS role_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        a.name IS NOT NULL
    GROUP BY
        c.movie_id, a.name, r.role
),
CompanyContribution AS (
    SELECT
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS contribution_count
    FROM
        movie_companies m
    JOIN
        company_name co ON m.company_id = co.id
    JOIN
        company_type ct ON m.company_type_id = ct.id
    GROUP BY
        m.movie_id, co.name, ct.kind
),
ImportantMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role_name,
        cc.company_name,
        cc.company_type,
        COALESCE(ar.role_count, 0) AS actor_role_count,
        COALESCE(cc.contribution_count, 0) AS company_contribution_count
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN
        CompanyContribution cc ON rm.movie_id = cc.movie_id
    WHERE
        rm.rank <= 5
)
SELECT
    movie_id,
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT role_name, ', ') AS roles,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', '; ') AS companies,
    SUM(actor_role_count) AS total_actor_roles,
    SUM(company_contribution_count) AS total_company_contributions
FROM
    ImportantMovies
GROUP BY
    movie_id, title, production_year
ORDER BY
    production_year DESC, movie_id;
