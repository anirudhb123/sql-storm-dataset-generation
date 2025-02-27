SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role,
    c.kind AS comp_cast_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type cct ON ci.role_id = cct.id
JOIN 
    role_type r ON ci.person_role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
