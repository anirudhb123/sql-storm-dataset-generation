WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_title,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COUNT(ar.actor_name) AS total_actors,
    mc.company_names,
    MAX(rm.rank) OVER () AS highest_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.title = ar.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.title = mc.movie_id
WHERE 
    mc.company_names IS NOT NULL 
    AND rm.production_year >= 2000
GROUP BY 
    rm.title, rm.production_year, mc.company_names
HAVING 
    COUNT(ar.actor_name) > 5
ORDER BY 
    rm.production_year DESC, rm.title;
