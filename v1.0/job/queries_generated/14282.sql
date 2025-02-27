SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    r.role AS person_role,
    c.name AS company_name,
    mt.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name ASC;
