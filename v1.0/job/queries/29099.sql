WITH relevant_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.nr_order,
        t.title AS movie_title,
        t.production_year
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        a.name LIKE '%John%' 
),
ranked_cast AS (
    SELECT 
        rc.movie_id,
        rc.actor_name,
        rc.role_name,
        rc.nr_order,
        rc.movie_title,
        rc.production_year,
        ROW_NUMBER() OVER (PARTITION BY rc.movie_id ORDER BY rc.nr_order) AS actor_rank
    FROM 
        relevant_cast rc
)
SELECT 
    rc.movie_id,
    rc.movie_title,
    rc.production_year,
    STRING_AGG(CONCAT(rc.actor_name, ' (', rc.role_name, ')'), ', ') AS actors
FROM 
    ranked_cast rc
GROUP BY 
    rc.movie_id, 
    rc.movie_title, 
    rc.production_year
ORDER BY 
    rc.production_year DESC, 
    rc.movie_title;