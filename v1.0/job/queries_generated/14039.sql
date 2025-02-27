SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    r.role AS role_type, 
    co.name AS company_name, 
    ci.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    role_type r ON c.role_id = r.id
ORDER BY 
    t.production_year DESC, a.name;
