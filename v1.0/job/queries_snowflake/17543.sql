SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS role_type
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC;
