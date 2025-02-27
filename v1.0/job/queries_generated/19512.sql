SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS role_name
FROM 
    cast_info AS ci
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    title AS m ON ci.movie_id = m.id
JOIN 
    role_type AS r ON ci.role_id = r.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, a.name;
