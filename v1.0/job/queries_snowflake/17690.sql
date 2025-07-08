SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.role_id AS role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
