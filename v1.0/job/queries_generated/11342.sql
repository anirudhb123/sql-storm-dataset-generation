SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    co.name AS company_name,
    r.role AS person_role,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info i ON t.id = i.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
