SELECT 
    t.title, 
    a.name AS actor_name, 
    c.role_id, 
    m.info AS movie_info
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title;
