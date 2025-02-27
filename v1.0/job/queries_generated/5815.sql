SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    p.info AS person_info, 
    r.role AS role_type, 
    ct.kind AS company_type_name, 
    co.name AS company_name, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id 
LEFT JOIN 
    company_name co ON mc.company_id = co.id 
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.production_year DESC, a.name;
