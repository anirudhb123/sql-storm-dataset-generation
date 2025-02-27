SELECT 
    a.id AS aka_name_id, 
    a.name AS aka_name, 
    t.id AS title_id, 
    t.title AS title, 
    c.person_role_id, 
    c.nr_order, 
    p.info AS person_info, 
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
