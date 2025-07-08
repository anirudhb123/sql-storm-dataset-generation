SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    ci.nr_order AS cast_order, 
    c.name AS character_name, 
    cp.kind AS cast_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    char_name c ON ci.role_id = c.id
JOIN 
    comp_cast_type cp ON ci.person_role_id = cp.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ci.nr_order;
