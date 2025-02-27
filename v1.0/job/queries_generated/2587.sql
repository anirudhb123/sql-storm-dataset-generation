WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ca
    JOIN 
        role_type r ON ca.person_role_id = r.id
    GROUP BY 
        ca.person_id, r.role
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        ct.kind IN ('Distributor', 'Production')
)
SELECT 
    rm.title,
    rm.production_year,
    ar.role_name,
    MAX(mc.company_name) AS lead_company,
    SUM(ar.role_count) AS total_roles,
    COUNT(DISTINCT mc.company_name) AS unique_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.title_id = ar.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.title_id = mc.movie_id
WHERE 
    rm.rn <= 10 AND
    (ar.role_name IS NOT NULL OR mc.company_name IS NOT NULL)
GROUP BY 
    rm.title_id, ar.role_name
ORDER BY 
    rm.production_year DESC, total_roles DESC;
