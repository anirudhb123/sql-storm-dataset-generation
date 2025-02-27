SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS comp_cast_type,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    title t ON t.id = at.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, actor_name;
