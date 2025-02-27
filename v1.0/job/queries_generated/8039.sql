SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.character AS role, 
    c.nr_order AS role_order, 
    co.name AS company_name, 
    p.info AS person_info 
FROM 
    aka_name ak 
JOIN 
    cast_info c ON ak.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    person_info p ON ak.person_id = p.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND c.nr_order < 5 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'biography') 
ORDER BY 
    ak.name, t.production_year DESC;
