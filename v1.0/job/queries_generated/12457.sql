SELECT 
    ak.name AS aka_name,
    ti.title AS movie_title,
    ci.note AS cast_note,
    cn.name AS company_name,
    ki.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    ti.production_year > 2000
ORDER BY 
    ti.production_year DESC;
