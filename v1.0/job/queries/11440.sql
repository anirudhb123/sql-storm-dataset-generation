SELECT 
    p.id AS person_id,
    p.name AS person_name,
    m.id AS movie_id,
    m.title AS movie_title,
    ci.note AS role_note,
    r.role AS role_name
FROM 
    aka_name AS p
JOIN 
    cast_info AS ci ON p.person_id = ci.person_id
JOIN 
    title AS m ON ci.movie_id = m.id
JOIN 
    role_type AS r ON ci.role_id = r.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, p.name;
