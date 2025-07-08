
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT COALESCE(rt.role, 'Unknown Role'), ', ') WITHIN GROUP (ORDER BY rt.role) AS roles,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        ar.roles,
        ar.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.company_count, 0) AS company_count,
    COALESCE(tm.actor_count, 0) AS actor_count,
    tm.roles,
    CASE 
        WHEN tm.company_count > 0 THEN 'Has Companies'
        ELSE 'No Companies'
    END AS company_status
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, tm.company_count DESC;
