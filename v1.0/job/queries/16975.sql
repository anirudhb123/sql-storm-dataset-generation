SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    r.role AS role_type
FROM 
    cast_info AS c
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    aka_title AS m ON c.movie_id = m.movie_id
JOIN 
    role_type AS r ON c.role_id = r.id
WHERE 
    m.production_year = 2020
ORDER BY 
    a.name;
