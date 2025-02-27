SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.info AS person_info, 
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
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND ci.kind = 'Production' 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography') 
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC;
