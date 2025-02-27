SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.person_role_id, 
    r.role AS role_name, 
    m.production_year 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
JOIN 
    movie_companies m ON t.id = m.movie_id 
WHERE 
    m.note IS NOT NULL 
ORDER BY 
    m.production_year DESC;
