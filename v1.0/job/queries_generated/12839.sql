SELECT 
    c.id AS cast_id,
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    p.info AS person_info,
    r.role AS role
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
