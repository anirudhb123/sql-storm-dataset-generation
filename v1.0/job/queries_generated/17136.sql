SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    rt.role AS role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
