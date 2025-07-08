WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'documentary'))
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
TotalRoles AS (
    SELECT 
        movie_id,
        COUNT(*) AS total_roles
    FROM 
        ActorRoles
    GROUP BY 
        movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COUNT(ar.actor_name) AS actor_count,
    COALESCE(tr.total_roles, 0) AS total_roles_count,
    AVG(ar.nr_order) AS avg_order_position
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    TotalRoles tr ON rm.movie_id = tr.movie_id
WHERE 
    rm.title_rank <= 5 
    AND (rm.production_year IS NOT NULL OR rm.production_year IS NOT NULL) 
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, tr.total_roles
HAVING 
    COUNT(ar.actor_name) > 0
ORDER BY 
    rm.production_year DESC, avg_order_position ASC;
