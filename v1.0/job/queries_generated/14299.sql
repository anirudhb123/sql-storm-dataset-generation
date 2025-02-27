SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    c.kind AS comp_cast_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    a.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    a.name;
