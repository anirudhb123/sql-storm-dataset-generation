SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.role_id, 
    ci.kind 
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id 
WHERE 
    t.production_year >= 2000 
ORDER BY 
    t.production_year DESC;
