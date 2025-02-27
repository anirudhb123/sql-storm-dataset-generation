SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_type,
    c.production_year,
    c.note AS cast_note
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    c.nr_order < 5
ORDER BY 
    c.production_year DESC, t.title;
