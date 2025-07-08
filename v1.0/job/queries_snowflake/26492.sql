
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
)

SELECT 
    rm.movie_title,
    LISTAGG(rm.actor_name, ', ') WITHIN GROUP (ORDER BY rm.actor_name) AS actor_list,
    COUNT(rm.actor_name) AS total_actors,
    LISTAGG(DISTINCT rm.actor_role, ', ') WITHIN GROUP (ORDER BY rm.actor_role) AS roles_list
FROM 
    RankedMovies rm
WHERE 
    rm.actor_rank <= 3  
GROUP BY 
    rm.movie_title, rm.production_year
ORDER BY 
    rm.production_year DESC, rm.movie_title;
