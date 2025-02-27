SELECT 
    p.name AS actor_name,
    m.title AS movie_title,
    c.kind AS role_type,
    m.production_year
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    p.name;
