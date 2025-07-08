SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS role
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC;
