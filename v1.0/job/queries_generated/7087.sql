SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    p.info AS person_info, 
    comp.name AS company_name, 
    key.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword key ON mk.keyword_id = key.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
  AND 
    a.name IS NOT NULL
  AND 
    comp.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name ASC;
