SELECT 
    t.title, 
    p.name AS person_name, 
    r.role AS person_role
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year = 2020
ORDER BY 
    t.title;
