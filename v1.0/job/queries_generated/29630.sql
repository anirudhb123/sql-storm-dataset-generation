WITH RankedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),

CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    GROUP BY 
        ci.movie_id
),

CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    cr.total_cast,
    cr.roles,
    cm.companies,
    cm.company_types
FROM 
    RankedTitles rt
JOIN 
    CastRoles cr ON rt.title_id = cr.movie_id
JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.rank = 1
ORDER BY 
    rt.production_year DESC, 
    rt.title;

This SQL query performs a comprehensive benchmarking of string processing involving titles, cast roles, and companies associated with movies. Each part of the query focuses on extracting and ranking information from multiple tables, maintaining clarity and organization for efficiently evaluating the underlying string processing capabilities of the database system.
