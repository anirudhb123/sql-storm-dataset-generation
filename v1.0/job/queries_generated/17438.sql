SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    r.role AS role_type,
    comp.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
