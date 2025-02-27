SELECT 
    p.id AS person_id, 
    p.name AS person_name, 
    m.title AS movie_title, 
    c.role_id AS role_id, 
    r.role AS role_name
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC;
