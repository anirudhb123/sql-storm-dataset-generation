SELECT 
    ak.name AS aka_name,
    ti.title AS movie_title,
    pi.info AS person_info,
    ct.kind AS company_type,
    ki.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title ti ON ci.movie_id = ti.id
JOIN 
    movie_info mi ON ti.id = mi.movie_id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    ti.production_year BETWEEN 2000 AND 2020
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
    AND ct.kind IN (SELECT kind FROM company_type WHERE kind LIKE 'Production%')
ORDER BY 
    ti.production_year DESC, ak.name;
