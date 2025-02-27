WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COALESCE(mi.info, 'N/A') AS additional_info
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COUNT(ar.actor_name) AS total_actors,
    STRING_AGG(DISTINCT ar.actor_name, ', ') AS actor_list,
    MAX(rm.rank) AS highest_rank,
    SUM(CASE WHEN ar.role_name = 'lead' THEN 1 ELSE 0 END) AS lead_roles_count,
    SUM(CASE WHEN ar.additional_info != 'N/A' THEN 1 ELSE 0 END) AS movies_with_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
HAVING 
    COUNT(ar.actor_name) > 2 AND SUM(CASE WHEN ar.role_name = 'supporting' THEN 1 ELSE 0 END) > 1
ORDER BY 
    rm.production_year DESC, rm.title;
