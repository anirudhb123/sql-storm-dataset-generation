SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    rt.role AS role_type,
    co.name AS company_name,
    mt.kind AS company_type,
    mi.info AS movie_info,
    kw.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND mt.kind ILIKE '%production%'
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
ORDER BY 
    t.production_year DESC, ak.name;
