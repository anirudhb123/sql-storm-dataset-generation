WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        r.role AS actor_role,
        COUNT(*) AS role_count
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.person_role_id = r.id
    GROUP BY
        ci.movie_id, ci.person_id, r.role
),

CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),

LongTitles AS (
    SELECT DISTINCT
        title_id,
        title
    FROM
        RankedTitles
    WHERE
        LENGTH(title) > 30
),

SubqueryRoles AS (
    SELECT
        movie_id,
        GROUP_CONCAT(DISTINCT actor_role) AS roles
    FROM
        ActorRoles
    GROUP BY
        movie_id
)

SELECT
    t.title,
    t.production_year,
    ld.company_name,
    ld.company_type,
    ar.roles,
    COUNT(*) FILTER (WHERE ar.role_count > 2) AS frequent_roles,
    CASE 
        WHEN ar.movie_id IS NULL THEN 'No Cast' 
        ELSE 'Has Cast' 
    END AS cast_presence
FROM
    LongTitles t
LEFT JOIN 
    CompanyDetails ld ON t.title_id = ld.movie_id
LEFT JOIN 
    SubqueryRoles ar ON t.title_id = ar.movie_id
FULL OUTER JOIN 
    aka_name a ON a.id = (
        SELECT MAX(a2.id)
        FROM aka_name a2
        WHERE a2.person_id = (SELECT MIN(person_id) FROM cast_info)
    )
GROUP BY
    t.title, t.production_year, ld.company_name, ld.company_type, ar.roles
HAVING 
    (COUNT(DISTINCT ld.company_name) > 1 OR COUNT(DISTINCT ld.company_name) IS NULL)
    AND (EXTRACT(YEAR FROM CURRENT_DATE) - MIN(t.production_year) < 10 OR MAX(t.production_year) IS NULL)
ORDER BY
    t.production_year DESC, t.title ASC
LIMIT 100 OFFSET 0;
