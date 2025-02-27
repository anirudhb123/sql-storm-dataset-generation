SELECT 
    na.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    ri.role AS role
FROM 
    cast_info ci
JOIN 
    aka_name na ON ci.person_id = na.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
JOIN 
    role_type ri ON ci.role_id = ri.id
WHERE 
    ti.production_year > 2000
ORDER BY 
    ti.production_year DESC, actor_name;
