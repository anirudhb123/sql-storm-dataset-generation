SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    n.name AS person_name,
    kt.kind AS kind,
    co.name AS company_name,
    mt.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name n ON a.person_id = n.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
