SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_name,
    c.note AS cast_note
FROM 
    cast_info c
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    actor_name;
