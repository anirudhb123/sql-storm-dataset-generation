-- Performance Benchmarking Query for Join Order
SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    at.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    mt.kind AS company_type,
    ti.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_info mi ON at.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    at.production_year >= 2000
ORDER BY 
    a.name, at.production_year DESC;
