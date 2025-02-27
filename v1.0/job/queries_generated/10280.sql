-- Performance Benchmarking Query
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.nr_order,
    r.role AS actor_role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, 
    a.name;
