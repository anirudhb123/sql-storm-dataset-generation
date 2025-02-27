SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    r.role AS role_type, 
    p.info AS person_info
FROM 
    aka_name ak 
JOIN 
    cast_info c ON ak.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
JOIN 
    person_info p ON ak.person_id = p.person_id 
WHERE 
    t.production_year >= 2000 
    AND r.role IN ('actor', 'actress') 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate') 
ORDER BY 
    t.production_year DESC, ak.name;
