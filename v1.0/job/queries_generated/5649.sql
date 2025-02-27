SELECT 
    ka.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    p.info AS person_info,
    co.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    aka_name ka
JOIN 
    cast_info c ON ka.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    person_info p ON ka.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
ORDER BY 
    t.production_year DESC, 
    ka.name, 
    c.nr_order;
