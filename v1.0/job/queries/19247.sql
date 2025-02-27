SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.note AS cast_note,
    r.role AS role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    m.production_year = 2020
ORDER BY 
    a.name;
