SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    r.role AS role_name,
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
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
