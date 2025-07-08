SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    rt.role AS role
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    role_type AS rt ON c.role_id = rt.id
WHERE 
    t.production_year = 2020
ORDER BY 
    a.name, t.title;
