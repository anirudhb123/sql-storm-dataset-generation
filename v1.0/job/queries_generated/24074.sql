WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS row_num,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
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
    GROUP BY 
        c.movie_id, a.name, r.role
),
TopRoles AS (
    SELECT 
        movie_id,
        actor_name,
        role_name,
        role_count,
        RANK() OVER (PARTITION BY movie_id ORDER BY role_count DESC) AS role_rank
    FROM 
        ActorRoles
    WHERE 
        role_count > 1
)
SELECT 
    rm.title,
    rm.production_year,
    tr.actor_name,
    tr.role_name,
    COALESCE(tr.role_count, 0) AS role_count,
    CASE 
        WHEN tr.role_rank IS NOT NULL THEN 'Top Role'
        ELSE 'Supporting Role'
    END AS role_type,
    NULLIF(rm.total_movies, 0) AS total_movies_released_this_year,
    CASE 
        WHEN tr.role_count IS NULL THEN 'No Roles Assigned' 
        ELSE 'Roles Assigned' 
    END AS role_assignment_status
FROM 
    RankedMovies rm
LEFT JOIN 
    TopRoles tr ON rm.movie_id = tr.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.title ASC;
