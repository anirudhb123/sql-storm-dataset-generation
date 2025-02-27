SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.name AS person_name,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info,
    rt.role AS role_type,
    ct.kind AS company_type
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON ak.person_id = p.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year = 2023
    AND ak.name IS NOT NULL
    AND p.gender = 'F'
ORDER BY 
    t.title, c.nr_order;
