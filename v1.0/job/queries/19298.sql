SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    rt.role AS role
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year >= 2020
ORDER BY 
    t.production_year DESC;
