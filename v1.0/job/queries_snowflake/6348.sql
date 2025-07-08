SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.role_id AS cast_role, 
    p.info AS person_info, 
    co.name AS company_name, 
    kt.keyword AS movie_keyword 
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
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword kt ON mk.keyword_id = kt.id 
WHERE 
    t.production_year > 2000 
    AND co.country_code = 'USA' 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography') 
ORDER BY 
    t.production_year DESC, ak.name;
