WITH movie_and_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        a.name AS actor_name,
        p.gender AS actor_gender,
        r.role AS actor_role
    FROM 
        aka_title m
    JOIN
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN
        person_info p ON a.person_id = p.person_id
    WHERE 
        m.production_year >= 2000
        AND a.name IS NOT NULL
)

SELECT 
    ma.movie_title,
    ma.production_year,
    COUNT(DISTINCT ma.actor_name) AS actor_count,
    STRING_AGG(DISTINCT ma.actor_name, ', ') AS actor_names,
    STRING_AGG(DISTINCT ma.actor_role, ', ') AS actor_roles
FROM 
    movie_and_cast ma
GROUP BY 
    ma.movie_title, ma.production_year
ORDER BY 
    ma.production_year DESC, 
    actor_count DESC
LIMIT 10;

This query achieves a comprehensive look into movies produced after the year 2000, summarizing the number of unique actors and their roles in each movie, while also collecting their names as a comma-separated string. The results are ordered by production year and the number of actors involved.
