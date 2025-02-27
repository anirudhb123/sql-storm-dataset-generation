SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    p.info AS person_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    person_info p ON a.id = p.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
