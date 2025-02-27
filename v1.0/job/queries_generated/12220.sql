SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.nr_order AS role_order,
    r.role AS role_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    person_info p ON p.person_id = a.person_id
JOIN 
    movie_info m ON m.movie_id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
