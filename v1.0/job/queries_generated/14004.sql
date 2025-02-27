SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.id AS cast_id,
    p.name AS person_name,
    r.role AS role_type,
    ti.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    info_type ti ON p.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
