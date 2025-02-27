SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_type,
    c.note AS cast_note,
    c.nr_order AS cast_order
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Some Info Type')
ORDER BY 
    t.production_year DESC, c.nr_order;
