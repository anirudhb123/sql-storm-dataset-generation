SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    person_info p ON a.id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
