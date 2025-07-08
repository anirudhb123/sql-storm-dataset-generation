
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
CastWithRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_role_id) AS role_count,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    cr.role_count,
    cr.roles,
    ci.company_count,
    ci.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CastWithRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    (rm.rn <= 10 OR ci.company_count IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
