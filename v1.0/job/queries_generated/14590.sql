SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role,
    c.nr_order AS role_order,
    m.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
ORDER BY 
    m.production_year DESC, 
    role_order ASC;
