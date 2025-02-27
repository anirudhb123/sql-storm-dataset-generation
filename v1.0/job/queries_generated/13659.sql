SELECT 
    p.id AS person_id,
    p.name AS person_name,
    t.id AS title_id,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_type
FROM 
    name p
JOIN 
    cast_info c ON p.id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, p.name;
