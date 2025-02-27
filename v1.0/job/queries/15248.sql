SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ci.role_id AS role
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC;
