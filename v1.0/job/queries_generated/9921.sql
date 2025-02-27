SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    r.role AS person_role,
    mi.info AS additional_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = it.id
WHERE 
    t.production_year >= 2000 
    AND k.keyword LIKE '%action%'
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    ak.name;
