SELECT 
    a.name AS aka_name, 
    c.nr_order, 
    t.title, 
    t.production_year, 
    comp.name AS company_name, 
    role.role AS person_role,
    mi.info AS movie_info 
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name comp ON mc.company_id = comp.id 
JOIN 
    role_type role ON c.role_id = role.id 
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    t.production_year > 2000 
    AND role.role LIKE '%actor%' 
ORDER BY 
    t.production_year DESC, 
    a.name;
