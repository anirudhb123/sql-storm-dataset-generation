SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    m.production_year,
    i.info AS movie_info
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    info_type i ON m.info_type_id = i.id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
ORDER BY 
    m.production_year DESC;
