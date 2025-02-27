SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    c.role_id,
    co.kind AS company_type,
    i.info AS movie_info
FROM 
    name p
JOIN 
    cast_info c ON p.id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type co ON mc.company_type_id = co.id
JOIN 
    movie_info i ON t.id = i.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, p.name;
