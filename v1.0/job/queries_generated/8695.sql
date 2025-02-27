SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    ki.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ak.md5sum IS NOT NULL
    AND c.country_code = 'USA'
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
ORDER BY 
    t.production_year DESC, ak.name, t.title;
