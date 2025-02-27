SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    cn.name AS company_name, 
    mt.kind AS company_type, 
    k.keyword AS movie_keyword, 
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
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
