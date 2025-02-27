WITH TitleInfo AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON mc.movie_id = t.movie_id
    LEFT JOIN
        company_name c ON c.id = mc.company_id
    WHERE
        t.production_year IS NOT NULL
        AND t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year
),
PersonRoleInfo AS (
    SELECT
        ci.movie_id,
        ai.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM
        cast_info ci
    JOIN
        aka_name ai ON ai.person_id = ci.person_id
    JOIN
        role_type rt ON rt.id = ci.role_id
),
MovieDetails AS (
    SELECT
        ti.title_id,
        ti.title,
        ti.production_year,
        ti.company_count,
        ti.companies,
        p.actor_name,
        p.role,
        p.role_order,
        CASE
            WHEN ti.company_count IS NULL THEN 'No Companies'
            WHEN ti.company_count > 5 THEN 'Multiple Companies'
            ELSE 'Single Company'
        END AS company_status
    FROM
        TitleInfo ti
    LEFT JOIN
        PersonRoleInfo p ON p.movie_id = ti.title_id
)
SELECT
    md.title,
    md.production_year,
    COALESCE(md.companies, 'N/A') AS companies,
    md.company_status,
    STRING_AGG(DISTINCT md.actor_name || ' as ' || md.role ORDER BY md.role_order) AS cast
FROM
    MovieDetails md
GROUP BY
    md.title,
    md.production_year,
    md.company_status
HAVING
    COUNT(DISTINCT md.actor_name) >= 1
    AND md.production_year IS NOT NULL
ORDER BY
    md.production_year DESC,
    md.title ASC
LIMIT 100;
