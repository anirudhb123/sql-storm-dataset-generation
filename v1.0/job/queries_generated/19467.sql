SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    c.note AS role_note,
    co.name AS company_name
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year = 2020
ORDER BY 
    p.name, t.title;
