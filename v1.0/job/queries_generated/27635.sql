WITH RankedCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY mc.note DESC) AS rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
CastRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_type,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
), 
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) as keyword_count,
        MIN(cmp.company_name) AS first_company
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        RankedCompanies cmp ON t.id = cmp.movie_id AND cmp.rank = 1
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword_count,
    cr.actor_name,
    cr.role_type,
    rc.company_name
FROM 
    MovieDetails md
JOIN 
    CastRoles cr ON md.movie_id = cr.movie_id
JOIN 
    RankedCompanies rc ON md.movie_id = rc.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title ASC, rc.company_name;
