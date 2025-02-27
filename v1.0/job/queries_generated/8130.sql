SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    ci.nr_order AS cast_order, 
    r.role AS role_name, 
    c.name AS company_name, 
    ti.info AS additional_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000 
    AND c.country_code = 'USA' 
    AND ti.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Oscar%')
ORDER BY 
    t.production_year DESC, 
    ak.name ASC;
