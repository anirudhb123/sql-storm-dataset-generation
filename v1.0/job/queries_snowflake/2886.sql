
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_per_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
), 
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COALESCE(rt.role, 'Unknown') AS role_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_count
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
    ci.companies,
    ar.actor_count,
    CASE 
        WHEN ar.actor_count IS NULL THEN 'No actors data'
        ELSE 'Data available'
    END AS actor_data_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
