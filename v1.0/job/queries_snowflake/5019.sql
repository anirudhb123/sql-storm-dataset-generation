SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.info AS person_info, 
    kom.name AS company_name, 
    k.keyword AS movie_keyword, 
    r.role AS person_role 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
JOIN 
    complete_cast cc ON cc.movie_id = t.id 
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
JOIN 
    company_name kom ON mc.company_id = kom.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year > 2000 
AND 
    kom.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    c.nr_order ASC;
