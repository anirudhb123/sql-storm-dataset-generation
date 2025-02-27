SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS cast_type,
    ci.note AS cast_note,
    c.nr_order AS cast_order
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    name p ON ci.person_id = p.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    ci.nr_order ASC;
