SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id AS role,
    ci.note AS cast_note,
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY 
    t.production_year DESC, 
    a.name;
