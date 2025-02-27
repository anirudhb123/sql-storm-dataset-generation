WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(cn.name) AS company_names,
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    mc.company_names,
    mc.company_types,
    ar.role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.year_rank <= 5 
  AND 
    (ar.role_name LIKE '%lead%' OR ar.role_name IS NULL)
ORDER BY 
    rm.production_year DESC, ar.actor_name;
