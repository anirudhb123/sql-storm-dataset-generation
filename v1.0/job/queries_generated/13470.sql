SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_type
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year = 2023
ORDER BY 
    ak.name, t.title;
