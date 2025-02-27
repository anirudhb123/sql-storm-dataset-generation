SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    c.kind AS comp_cast_kind,
    comp.name AS company_name,
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
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Some Info') 
ORDER BY 
    t.production_year DESC;
