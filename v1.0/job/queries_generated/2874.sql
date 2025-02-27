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
        ci.person_id,
        ci.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id, ci.movie_id, r.role
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
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
    ar.person_id,
    ar.role,
    ar.role_count,
    cmi.company_names,
    cmi.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyMovieInfo cmi ON rm.movie_id = cmi.movie_id
WHERE 
    (ar.role IS NOT NULL OR cmi.company_names IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.rank, ar.role_count DESC;
