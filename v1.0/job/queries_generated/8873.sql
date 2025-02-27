SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    c.nr_order AS cast_order, 
    co.name AS company_name, 
    ct.kind AS company_type, 
    m.info AS movie_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_info m ON t.id = m.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    a.name_pcode_cf IS NOT NULL 
    AND t.production_year > 2000 
    AND c.nr_order < 5 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
