WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COALESCE(MAX(cn.name), 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.role,
    ar.role_count,
    cd.company_name,
    cd.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC,
    rm.title ASC
UNION
SELECT 
    NULL AS movie_id,
    NULL AS title,
    NULL AS production_year,
    NULL AS role,
    NULL AS role_count,
    'Total Movies' AS company_name,
    COUNT(*) AS company_type
FROM 
    RankedMovies
HAVING 
    COUNT(*) > 20
ORDER BY 
    production_year DESC;
