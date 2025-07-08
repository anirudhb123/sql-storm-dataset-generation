SELECT 
    t.title, 
    a.name AS actor_name, 
    r.role AS role_name,
    c.note AS cast_note
FROM 
    title AS t
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
