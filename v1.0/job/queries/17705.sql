SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    rt.role AS role_description
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year = 2020
ORDER BY 
    a.name, t.title;
