SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_type
FROM 
    cast_info ci
JOIN 
    aka_name n ON ci.person_id = n.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    n.name;
