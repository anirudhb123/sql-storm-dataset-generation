SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id AS role
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    t.production_year = 2023
ORDER BY 
    a.name;
