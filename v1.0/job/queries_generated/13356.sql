SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.id AS title_id, 
    t.title AS movie_title, 
    c.id AS cast_id, 
    c.person_role_id, 
    p.id AS person_id, 
    p.name AS person_name 
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON c.person_id = p.person_id
ORDER BY 
    a.id, t.production_year DESC;
