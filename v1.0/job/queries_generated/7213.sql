SELECT 
    ak.name AS aka_name,
    t.title AS title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    it.info AS movie_info,
    ct.kind AS company_type,
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
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
    AND it.info IS NOT NULL
ORDER BY 
    t.production_year DESC, ak.name;
