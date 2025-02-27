WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year IS NOT NULL
),

ActorRole AS (
    SELECT
        a.name AS actor_name,
        r.role AS character_name,
        c.movie_id
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),

MovieCompanies AS (
    SELECT
        m.title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        aka_title m
    JOIN
        movie_companies mc ON m.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),

CompleteCast AS (
    SELECT
        m.title,
        COUNT(DISTINCT a.actor_name) AS total_actors,
        COUNT(DISTINCT a.character_name) AS unique_roles
    FROM
        RankedTitles rt
    JOIN
        ActorRole a ON rt.title_id = a.movie_id
    GROUP BY
        rt.title_id, rt.title
)

SELECT
    rt.title,
    rt.production_year,
    CONCAT('This movie features ', cc.total_actors, ' actors playing ', cc.unique_roles, ' unique roles.') AS cast_summary,
    GROUP_CONCAT(DISTINCT mc.company_name || ' (' || mc.company_type || ')') AS companies_involved
FROM
    RankedTitles rt
JOIN
    CompleteCast cc ON rt.title_id = cc.title_id
LEFT JOIN
    MovieCompanies mc ON rt.title = mc.title
WHERE
    rt.rank = 1 AND rt.production_year >= 2000
GROUP BY
    rt.title, rt.production_year, cc.total_actors, cc.unique_roles
ORDER BY
    rt.production_year DESC;
