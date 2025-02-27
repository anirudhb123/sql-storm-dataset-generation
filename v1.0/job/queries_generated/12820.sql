SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS role_type, 
    r.role AS character_name 
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    company_name cn ON t.id = cn.imdb_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
