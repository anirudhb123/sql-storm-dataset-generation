SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    c.note AS cast_note,
    comp.name AS company_name,
    r.role AS role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND comp.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name;
