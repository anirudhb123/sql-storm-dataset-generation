SELECT 
    ak.name AS aka_name,
    ti.title AS title,
    ci.nr_order AS cast_order,
    co.name AS company_name,
    it.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON ti.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    ti.production_year DESC, 
    ci.nr_order;
