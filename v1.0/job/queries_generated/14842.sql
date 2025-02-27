SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS role_note,
    comp.name AS company_name,
    ki.kind AS kind_type,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type ki ON t.kind_id = ki.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
