SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    p.name AS person_name, 
    c.kind AS cast_type 
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
JOIN 
    name p ON ak.person_id = p.id
WHERE 
    t.production_year = 2023;
