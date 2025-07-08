
WITH RankedTitles AS (
    SELECT
        at.title,
        at.production_year,
        at.id AS title_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS title_rank
    FROM
        aka_title at
    WHERE
        at.production_year BETWEEN 2000 AND 2023
),

CastInfoWithRoles AS (
    SELECT
        ci.movie_id,
        ci.person_role_id,
        r.role,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS role_count
    FROM
        cast_info ci
    LEFT JOIN
        role_type r ON ci.role_id = r.id
),

MoviesWithCompany AS (
    SELECT
        mv.id AS movie_id,
        mv.title,
        cc.kind AS company_kind,
        COUNT(mo.company_id) AS company_count
    FROM
        aka_title mv
    JOIN
        movie_companies mo ON mv.id = mo.movie_id
    LEFT JOIN
        company_type cc ON mo.company_type_id = cc.id
    WHERE
        EXISTS (
            SELECT 1
            FROM company_name cn
            WHERE cn.id = mo.company_id 
            AND cn.name IS NOT NULL
            AND cn.country_code = 'USA'
        )
    GROUP BY
        mv.id, mv.title, cc.kind
),

FinalResults AS (
    SELECT
        rt.title,
        rt.production_year,
        cwr.person_role_id,
        cwr.role,
        cwr.role_count,
        mc.company_kind,
        mc.company_count
    FROM
        RankedTitles rt
    LEFT JOIN
        CastInfoWithRoles cwr ON rt.title_id = cwr.movie_id
    LEFT JOIN
        MoviesWithCompany mc ON rt.title_id = mc.movie_id
    WHERE
        (cwr.role_count IS NULL OR cwr.role_count > 1) AND
        mc.company_count >= 1
)

SELECT
    title,
    production_year,
    role,
    COUNT(NULLIF(role, '')) OVER (PARTITION BY production_year) AS roles_assigned,
    LISTAGG(DISTINCT company_kind, ', ') AS unique_company_kinds,
    NULLIF(MIN(company_count), 0) AS min_company_count
FROM
    FinalResults
GROUP BY
    title, production_year, role
HAVING
    MAX(role) IS NOT NULL
ORDER BY
    production_year DESC, title;
