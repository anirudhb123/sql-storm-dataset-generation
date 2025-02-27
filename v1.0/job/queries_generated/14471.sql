SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ROLE.role AS character_name,
    c.kind AS cast_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type ROLE ON ci.role_id = ROLE.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
