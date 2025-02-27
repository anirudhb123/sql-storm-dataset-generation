SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    co.name AS company_name,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info,
    ri.role AS person_role
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    role_type ri ON c.role_id = ri.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, ak.name;
