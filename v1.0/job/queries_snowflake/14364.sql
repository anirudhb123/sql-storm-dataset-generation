SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year AS movie_year,
    r.role AS character_role
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, a.name;
