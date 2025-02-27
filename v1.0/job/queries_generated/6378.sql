SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    k.keyword AS keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_name c ON c.id IN (SELECT mc.company_id FROM movie_companies mc WHERE mc.movie_id = t.id)
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON pi.person_id = ak.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND ak.name IS NOT NULL 
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, ak.name;
