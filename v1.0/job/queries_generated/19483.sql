SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_title
FROM 
    title t
JOIN 
    cast_info c ON c.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = c.person_id
JOIN 
    role_type r ON r.id = c.role_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year, a.name;
