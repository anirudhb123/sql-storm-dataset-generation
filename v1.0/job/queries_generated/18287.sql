SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.nr_order AS cast_order,
    rt.role AS role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    m.production_year = 2023;
