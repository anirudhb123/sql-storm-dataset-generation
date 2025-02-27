SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.nr_order AS role_order,
    r.role AS role,
    t.production_year
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    title t ON m.id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, c.nr_order;
