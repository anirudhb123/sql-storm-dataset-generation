WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id, a.name, r.role
)
SELECT 
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    ar.role_count,
    CASE 
        WHEN ar.role_count IS NULL THEN 'No Roles'
        ELSE 'Has Roles'
    END AS role_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title, ar.actor_name;
