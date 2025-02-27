SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.name AS person_name,
    ct.kind AS comp_cast_type,
    co.name AS company_name,
    ki.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON a.person_id = p.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    comp_cast_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name, 
    t.title;
