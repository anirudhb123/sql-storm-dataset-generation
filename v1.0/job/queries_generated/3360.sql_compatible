
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT r.role, ',' ORDER BY r.role) AS roles_list,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ar.actor_count, 0) AS total_actors,
    ar.roles_list,
    CASE 
        WHEN ar.actor_count IS NULL THEN 'No Actors'
        ELSE 'Actors Available'
    END AS actor_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
WHERE 
    rm.rn <= 10
GROUP BY 
    rm.title,
    rm.production_year,
    ar.actor_count,
    ar.roles_list
ORDER BY 
    rm.production_year DESC, rm.title ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
