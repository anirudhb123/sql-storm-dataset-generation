SELECT 
    p.id AS person_id,
    p.name AS person_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS role
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC;
