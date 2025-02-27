WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
TitleWithRole AS (
    SELECT 
        t.title AS movie_title,
        cg.role AS cast_role,
        COUNT(ci.person_id) AS role_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type cg ON ci.role_id = cg.id
    GROUP BY 
        t.title, cg.role
),
MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title AS movie_title,
    rt.production_year,
    rt.cast_count,
    cr.company_name,
    cr.company_type,
    tr.cast_role,
    tr.role_count,
    md.movie_info
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyRoles cr ON rt.title = cr.movie_title
LEFT JOIN 
    TitleWithRole tr ON rt.title = tr.movie_title
LEFT JOIN 
    MovieInfoDetails md ON rt.title = md.movie_id
WHERE 
    rt.rank_per_year = 1 AND
    (tr.role_count > 2 OR cr.company_type IS NULL)
ORDER BY 
    rt.production_year DESC,
    rt.cast_count DESC,
    cr.company_name ASC;
