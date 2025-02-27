SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    cii.note AS cast_note,
    cn.name AS company_name,
    kt.keyword AS movie_keyword,
    pi.info AS person_info,
    rt.role AS role_type
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ak.name LIKE '%Smith%'
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, ak.name ASC
LIMIT 100;
