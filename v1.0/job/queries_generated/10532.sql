SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS title_name,
    c.person_role_id AS role_id,
    r.role AS role_name
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
WHERE 
    t.production_year >= 2000 
ORDER BY 
    t.production_year DESC, 
    a.name;
