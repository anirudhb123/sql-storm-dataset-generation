WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
),
ActorRoles AS (
    SELECT
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, r.role
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.role,
    ar.role_count,
    ci.company_name,
    ci.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.title = ar.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.title = ci.movie_id
WHERE 
    rm.rn <= 5
  AND 
    (ar.role IS NOT NULL OR ci.company_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, ar.role_count DESC;
