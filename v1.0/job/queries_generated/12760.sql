SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    p.name AS person_name, 
    r.role AS person_role, 
    c.kind AS comp_cast_type, 
    k.keyword AS movie_keyword, 
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    comp_cast_type c ON cc.subject_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    r.role = 'actor' 
AND 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
