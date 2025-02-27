SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS comp_cast_type,
    ci.name AS company_name,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c_info ON a.person_id = c_info.person_id
JOIN 
    title t ON c_info.movie_id = t.id
JOIN 
    person_info p ON c_info.person_id = p.person_id
JOIN 
    comp_cast_type c ON c_info.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
