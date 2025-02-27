WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        co.country_code,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    cm.company_name,
    cm.country_code,
    cm.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyMovieInfo cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    ar.actor_name NULLS LAST
UNION ALL
SELECT 
    NULL AS movie_id,
    NULL AS title,
    NULL AS production_year,
    'Unknown Actor' AS actor_name,
    'Unknown Role' AS role_name,
    COALESCE(cm.company_name, 'Independent') AS company_name,
    COALESCE(cm.country_code, 'N/A') AS country_code,
    COALESCE(cm.company_type, 'N/A') AS company_type
FROM 
    CompanyMovieInfo cm
WHERE 
    cm.company_name IS NULL
ORDER BY 
    company_name;
