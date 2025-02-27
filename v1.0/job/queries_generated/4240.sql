WITH MovieTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT mc.company_id) AS production_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name, 
        r.role AS role_name, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
),
TopMovies AS (
    SELECT 
        mt.title_id, 
        mt.title, 
        mt.production_year, 
        mt.production_count,
        COALESCE(ar.actor_name, 'Unknown Actor') AS actor_name,
        COALESCE(ar.role_name, 'Unknown Role') AS role_name
    FROM 
        MovieTitles mt
    LEFT JOIN 
        ActorRoles ar ON ar.movie_id = mt.title_id
    WHERE 
        mt.production_count > 0
)
SELECT 
    t.title, 
    t.production_year, 
    STRING_AGG(DISTINCT CONCAT(a.actor_name, ' (', a.role_name, ')'), ', ') AS actors_roles
FROM 
    TopMovies t
LEFT JOIN 
    ActorRoles a ON t.title_id = a.movie_id
GROUP BY 
    t.title, t.production_year
HAVING 
    COUNT(a.actor_name) >= 2
ORDER BY 
    t.production_year DESC, 
    t.title;
