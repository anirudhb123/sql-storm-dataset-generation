SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    a.person_id,
    t.id AS title_id,
    t.title AS movie_title,
    t.production_year,
    c.id AS cast_info_id,
    c.note AS cast_note,
    r.role AS role_name,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
