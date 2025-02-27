SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ci.nr_order AS role_order, 
    rt.role AS role_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year >= 2020
ORDER BY 
    t.production_year DESC, 
    a.name;
