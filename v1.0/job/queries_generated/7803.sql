SELECT 
    ak.name AS aka_name,
    ct.kind AS company_type,
    ti.title AS movie_title,
    mc.note AS company_note,
    pi.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    title ti ON cc.subject_id = ti.id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ti.production_year > 2000 
    AND ak.name IS NOT NULL 
    AND ct.kind IS NOT NULL 
ORDER BY 
    ti.production_year DESC, ak.name ASC;
