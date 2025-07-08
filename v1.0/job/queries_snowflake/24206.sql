
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CountedRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS unique_role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
NullRoleStats AS (
    SELECT 
        ci.movie_id,
        SUM(CASE WHEN ci.role_id IS NULL THEN 1 ELSE 0 END) AS null_role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
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
FinalResults AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.kind_id,
        cr.unique_role_count,
        nrs.null_role_count,
        cd.company_name,
        cd.company_type
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CountedRoles cr ON rt.title_id = cr.movie_id
    LEFT JOIN 
        NullRoleStats nrs ON rt.title_id = nrs.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rt.title_id = cd.movie_id
    WHERE 
        rt.rank <= 5 AND 
        (cr.unique_role_count IS NOT NULL OR nrs.null_role_count IS NOT NULL)
)
SELECT 
    title,
    production_year,
    COALESCE(unique_role_count, 0) AS unique_roles,
    COALESCE(null_role_count, 0) AS null_roles,
    LISTAGG(DISTINCT company_name, ', ') AS companies,
    LISTAGG(DISTINCT company_type, ', ') AS company_types
FROM 
    FinalResults
GROUP BY 
    title, production_year, unique_role_count, null_role_count
ORDER BY 
    production_year DESC, unique_roles DESC, null_roles ASC;
