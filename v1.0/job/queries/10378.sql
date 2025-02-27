SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    r.role AS person_role,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    role_type r ON c.role_id = r.id 
JOIN 
    movie_info m ON c.movie_id = m.movie_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')
ORDER BY 
    t.production_year DESC;
