WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc 
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS actor_role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        coalesce(ar.actor_role, 'No Role') AS actor_role,
        coalesce(ar.role_count, 0) AS role_count,
        cc.company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        CompanyCounts cc ON rm.movie_id = cc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.actor_role,
    m.role_count,
    m.company_count,
    CASE 
        WHEN m.company_count IS NULL THEN 'No Companies Associated'
        WHEN m.company_count > 5 THEN 'High Production'
        ELSE 'Moderate Production'
    END AS production_category
FROM 
    MoviesWithActors m
WHERE 
    m.rank_within_year <= 5
ORDER BY 
    m.production_year DESC, 
    m.company_count DESC;
