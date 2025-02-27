SELECT 
    ak.name AS aka_name,
    t.title,
    c.note AS cast_note,
    p.info AS person_info,
    co.name AS company_name,
    r.role AS role_type
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year > 2000 
    AND co.country_code = 'USA' 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, ak.name;
