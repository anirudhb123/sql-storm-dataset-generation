WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
person_roles AS (
    SELECT
        ci.person_id,
        ci.movie_id,
        rt.role,
        SUM(CASE WHEN ci.note IS NOT NULL AND ci.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_role_count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.person_id, ci.movie_id, rt.role
),
company_info AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
aggregated_info AS (
    SELECT
        t.title,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ci.movie_id,
        COALESCE(ci.lead_role_count, 0) AS lead_roles,
        c.companies
    FROM
        aka_title t
    LEFT JOIN
        person_roles ci ON t.id = ci.movie_id
    LEFT JOIN
        company_info c ON t.id = c.movie_id
    LEFT JOIN
        ranked_titles r ON t.id = r.title_id
    WHERE
        r.title_rank <= 5 OR r.title_rank IS NULL
    GROUP BY
        t.title, rt.role, ci.movie_id, ci.lead_role_count, c.companies
)
SELECT
    title,
    role,
    actor_count,
    lead_roles,
    companies
FROM
    aggregated_info
WHERE 
    actor_count > 0
ORDER BY
    lead_roles DESC,
    title ASC
LIMIT 10
OFFSET 5
UNION ALL
SELECT
    'Unknown Title' AS title,
    'Unknown Role' AS role,
    0 AS actor_count,
    0 AS lead_roles,
    'None' AS companies
WHERE NOT EXISTS (
    SELECT 1
    FROM aggregated_info
);
