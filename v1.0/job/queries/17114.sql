SELECT 
    t.title, 
    p.name AS person_name, 
    r.role 
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title;
