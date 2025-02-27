SELECT DISTINCT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    rc.role AS role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type rc ON c.role_id = rc.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.production_year DESC, a.name;
