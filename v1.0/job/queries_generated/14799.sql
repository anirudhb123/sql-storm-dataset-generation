SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    pn.name AS person_name,
    rt.role AS person_role,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name pn ON c.person_id = pn.id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
