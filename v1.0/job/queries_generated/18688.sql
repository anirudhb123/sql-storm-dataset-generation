SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS role_type, 
    m.production_year 
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
ORDER BY 
    m.production_year DESC;
