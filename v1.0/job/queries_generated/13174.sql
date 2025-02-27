SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    n.name AS person_name,
    r.role AS role_type,
    m.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name n ON a.person_id = n.imdb_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    m.production_year DESC;
