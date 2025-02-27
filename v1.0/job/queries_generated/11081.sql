SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.person_role_id,
    c.nr_order,
    r.role AS role_type,
    m.production_year
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    title m ON c.movie_id = m.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    a.name;
