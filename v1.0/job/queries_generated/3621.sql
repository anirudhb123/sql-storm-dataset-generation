WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role LIKE '%lead%'
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(ar.actor_name, 'No Lead Actor') AS lead_actor,
    rm.production_year,
    ar.total_roles,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(rm.production_year AS TEXT)
    END AS year_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
WHERE 
    rm.title_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
