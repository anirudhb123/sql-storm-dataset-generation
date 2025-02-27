SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_name,
    r.role AS role_type,
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
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
ORDER BY 
    m.production_year DESC;
