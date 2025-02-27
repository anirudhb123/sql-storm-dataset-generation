SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    co.name AS company_name, 
    kt.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year >= 2000 
AND 
    ak.name IS NOT NULL 
ORDER BY 
    t.production_year DESC,
    ak.name;
