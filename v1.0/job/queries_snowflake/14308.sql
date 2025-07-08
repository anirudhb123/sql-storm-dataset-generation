SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    ti.info AS movie_info 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id 
JOIN 
    comp_cast_type c ON ci.role_id = c.id 
WHERE 
    t.production_year >= 2000 
ORDER BY 
    t.production_year DESC, 
    a.name;
