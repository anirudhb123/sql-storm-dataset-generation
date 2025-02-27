SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    c.role_id AS cast_role_id,
    ci.kind AS cast_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
JOIN 
    movie_info m ON cc.movie_id = m.movie_id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
