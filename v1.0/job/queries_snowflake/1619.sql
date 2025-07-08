
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.id ASC) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
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
MovieInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(mn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name mn ON mc.company_id = mn.id
    WHERE 
        mn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.actor_name, 'Unknown') AS actor_name,
    COALESCE(ar.role_name, 'Unknown Role') AS role_name,
    COALESCE(mi.company_names, 'No Companies') AS companies,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.year_rank <= 5 
ORDER BY 
    rm.production_year DESC, rm.title;
