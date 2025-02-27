SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ci.kind AS comp_cast_kind,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
