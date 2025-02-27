SELECT 
    m.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role
FROM 
    title m
JOIN 
    cast_info ci ON m.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
