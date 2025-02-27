SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    r.role AS role,
    c.kind AS comp_cast_type,
    c2.name AS company_name
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
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c2 ON mc.company_id = c2.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
