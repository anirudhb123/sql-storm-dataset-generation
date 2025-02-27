SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    pn.name AS person_name, 
    ct.kind AS company_type, 
    i.info AS movie_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    name pn ON c.person_id = pn.imdb_id 
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_info mi ON mi.movie_id = t.id 
JOIN 
    keyword k ON k.id = mi.info_type_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.production_year DESC;
