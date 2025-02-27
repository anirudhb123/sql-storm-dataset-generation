SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.note AS cast_note,
    ct.kind AS cast_type,
    info.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    movie_info info ON t.id = info.movie_id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
