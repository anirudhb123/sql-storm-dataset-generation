SELECT 
    n.name AS person_name,
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ct.kind AS company_type,
    ki.keyword AS movie_keyword
FROM 
    name n
JOIN 
    aka_name a ON n.id = a.person_id
JOIN 
    cast_info c ON n.id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
