SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    m.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year = 2020
ORDER BY 
    t.title, a.name;
