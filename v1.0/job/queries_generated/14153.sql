SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    c.note AS cast_note,
    m.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info LIKE '%Award%'
ORDER BY 
    m.production_year DESC, 
    t.title;
