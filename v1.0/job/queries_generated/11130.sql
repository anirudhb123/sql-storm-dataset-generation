SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    p.info AS person_info,
    r.role AS role_type,
    kom.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type kom ON mc.company_type_id = kom.id
ORDER BY 
    t.production_year DESC, 
    a.name;
