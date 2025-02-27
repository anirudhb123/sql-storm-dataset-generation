WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) OVER (PARTITION BY c.movie_id, r.role ORDER BY a.name) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    ar.role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
WHERE 
    rm.rank_by_title <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title, 
    ar.role_count DESC NULLS LAST;
