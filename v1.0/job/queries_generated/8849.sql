SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    cii.note AS cast_note,
    cn.name AS company_name,
    ct.kind AS company_type,
    ki.keyword AS movie_keyword,
    pi.info AS person_info,
    r.role AS role_type
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000
AND 
    ak.name IS NOT NULL
ORDER BY 
    t.production_year DESC, ak.name;
