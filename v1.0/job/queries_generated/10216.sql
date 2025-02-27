SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_name
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
