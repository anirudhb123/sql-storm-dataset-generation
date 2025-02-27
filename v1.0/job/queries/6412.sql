SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.id AS title_id, 
    t.title AS movie_title, 
    t.production_year, 
    ct.kind AS company_type, 
    cn.name AS company_name, 
    p.info AS person_info 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year > 2000 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography') 
ORDER BY 
    t.production_year DESC, 
    a.name;
