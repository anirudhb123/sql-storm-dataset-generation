WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id 
    GROUP BY 
        ci.movie_id, a.name, rt.role
    HAVING 
        COUNT(*) > 1
),
CompanyInfo AS (
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
)
SELECT 
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    COALESCE(ci.company_name, 'Independent') AS production_company,
    SUM(ar.role_count) OVER (PARTITION BY rm.movie_id ORDER BY ar.role_count DESC) AS total_actor_roles
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.production_year > 1980
    AND (ar.role_name IS NOT NULL OR ci.company_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
