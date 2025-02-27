SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year = 2020
ORDER BY 
    a.name;
