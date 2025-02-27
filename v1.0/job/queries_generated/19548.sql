SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    r.role AS role
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    r.role = 'Actor'
ORDER BY 
    t.production_year DESC;
