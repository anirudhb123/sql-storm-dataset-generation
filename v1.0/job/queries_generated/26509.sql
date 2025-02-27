WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorsWithRoles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
CompanyDetails AS (
    SELECT
        m.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        GROUP_CONCAT(DISTINCT co.name) AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        title m ON mc.movie_id = m.id
    GROUP BY
        mc.movie_id
),
TitleWithActorCount AS (
    SELECT
        rt.title,
        rt.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM
        RankedTitles rt
    LEFT JOIN (
        SELECT
            movie_id,
            COUNT(DISTINCT actor_name) AS actor_count
        FROM
            ActorsWithRoles
        GROUP BY
            movie_id
    ) ac ON rt.title_id = ac.movie_id
),
FinalBenchmark AS (
    SELECT
        t.title,
        t.production_year,
        c.company_count,
        t.actor_count
    FROM
        TitleWithActorCount t
    JOIN
        CompanyDetails c ON t.title_id = c.movie_id
    WHERE
        t.actor_count > 2
    ORDER BY
        t.production_year DESC,
        t.actor_count DESC
)
SELECT
    title,
    production_year,
    company_count,
    actor_count
FROM
    FinalBenchmark
LIMIT 100;
