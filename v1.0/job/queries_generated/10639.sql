SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    c.status_id AS complete_cast_status
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    pi.info_type_id = 1 -- Example filter for a specific info type
ORDER BY 
    t.production_year DESC, ak.name;
