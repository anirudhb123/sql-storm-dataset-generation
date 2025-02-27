SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    pt.kind AS role_type
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    role_type pt ON c.role_id = pt.id
WHERE 
    t.production_year = 2023
ORDER BY 
    c.nr_order;
