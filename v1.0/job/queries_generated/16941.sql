SELECT 
    t.title,
    a.name AS actor_name,
    r.role AS role_name,
    c.production_year
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    c.nr_order = 1
ORDER BY 
    c.production_year DESC;
