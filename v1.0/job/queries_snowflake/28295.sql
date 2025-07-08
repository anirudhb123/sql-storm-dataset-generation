
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        r.role,
        a.name AS actor_name,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY r.role) AS role_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        role_type r ON c.person_role_id = r.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year > 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
)

SELECT 
    rm.movie_id,
    rm.title,
    LISTAGG(rm.actor_name, ', ') WITHIN GROUP (ORDER BY rm.role_rank) AS actor_list,
    COUNT(rm.actor_name) AS total_actors,
    MIN(rm.production_year) AS earliest_year
FROM 
    ranked_movies rm
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
HAVING 
    COUNT(rm.actor_name) > 5
ORDER BY 
    earliest_year DESC;
