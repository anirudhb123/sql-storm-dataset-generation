SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.role_id AS role,
    comp.name AS company_name,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info m ON t.movie_id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
